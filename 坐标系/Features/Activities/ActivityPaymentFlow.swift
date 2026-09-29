//
//  ActivityPaymentFlow.swift
//  坐标系
//
//  本地模拟支付流程（无真实后端）：下单 → 确认支付 → 参加。
//

import Foundation
import SwiftUI
import CoordinateModels

enum ActivityOrderStatus: String, Codable {
    case pending
    case paid
    case cancelled
    case refunding
    case refunded
}

struct ActivityOrder: Identifiable, Codable, Hashable {
    let id: UUID
    let activityID: UUID
    let activityTitle: String
    let feeDisplay: String
    let amountCents: Int
    let createdAt: Date
    var status: ActivityOrderStatus
    var paymentMethod: String
}

enum ActivityFeeParser {
    /// 免费或店内自费不可 App 内支付；其余返回展示文案与模拟金额（分）
    static func payableAmount(for activity: Activity) -> (display: String, cents: Int)? {
        guard activity.requiresInAppPayment else { return nil }
        let fee = activity.fee.trimmingCharacters(in: .whitespacesAndNewlines)

        if let yuan = extractYuan(from: fee) {
            return (fee, max(yuan, 1) * 100)
        }
        return (fee, fallbackCents(for: activity))
    }

    static func formattedPrice(cents: Int) -> String {
        let yuan = Double(cents) / 100
        if yuan.truncatingRemainder(dividingBy: 1) == 0 {
            return "¥\(Int(yuan))"
        }
        return String(format: "¥%.2f", yuan)
    }

    private static func extractYuan(from fee: String) -> Int? {
        let pattern = /(\d+)/
        guard let match = fee.firstMatch(of: pattern) else { return nil }
        return Int(match.1)
    }

    private static func fallbackCents(for activity: Activity) -> Int {
        6800 + abs(activity.id.stableSeed % 5) * 1000
    }
}

@MainActor
enum ActivityPaymentStore {
    /// 由 `AppDerivedStateService` 在 `AppModel` 就绪后注入。
    static var walletStore: WalletStore?
    static var walletPassStore: WalletPassStore?

    private static let fileName = "activity_orders.json"
    private static var cache: [ActivityOrder] = loadAll()

    private static func requireWallet() -> WalletStore? { walletStore }
    private static func requirePassStore() -> WalletPassStore? { walletPassStore }

    static func orders(for activityID: Activity.ID) -> [ActivityOrder] {
        cache.filter { $0.activityID == activityID }.sorted { $0.createdAt > $1.createdAt }
    }

    static func paidOrder(for activityID: Activity.ID) -> ActivityOrder? {
        orders(for: activityID).first { $0.status == .paid }
    }

    /// 详情页订单区：已支付优先，否则展示退款中 / 已退款。
    static func displayOrder(for activityID: Activity.ID) -> ActivityOrder? {
        paidOrder(for: activityID)
            ?? orders(for: activityID).first {
                $0.status == .refunded || $0.status == .refunding
            }
    }

    static func hasPaid(for activityID: Activity.ID) -> Bool {
        paidOrder(for: activityID) != nil
    }

    static func allOrders() -> [ActivityOrder] {
        cache.sorted { $0.createdAt > $1.createdAt }
    }

    static func order(id: UUID) -> ActivityOrder? {
        cache.first { $0.id == id }
    }

    @discardableResult
    static func requestRefund(orderID: UUID) -> String? {
        guard let index = cache.firstIndex(where: { $0.id == orderID }) else {
            return "订单不存在"
        }
        guard cache[index].status == .paid else {
            return "当前订单不可退款"
        }
        cache[index].status = .refunding
        persist()
        return nil
    }

    static func finalizeRefund(orderID: UUID) {
        guard let index = cache.firstIndex(where: { $0.id == orderID }) else { return }
        guard cache[index].status == .refunding else { return }
        guard let wallet = requireWallet() else { return }
        let order = cache[index]
        let method = PaymentMethod.resolve(order.paymentMethod)
        wallet.credit(
            amountCents: order.amountCents,
            method: method,
            kind: .activityRefund,
            title: order.activityTitle,
            subtitle: "活动退款",
            relatedID: order.id
        )
        cache[index].status = .refunded
        persist()
        requirePassStore()?.void(relatedID: order.id)
    }

    /// 主办取消活动时，批量退款已支付订单。
    /// DEBUG：本地即时完结；Release：仅标记退款中（由 RefundFlow / 服务端确认）。
    static func refundAllPaidOrders(for activityID: Activity.ID) {
        for order in orders(for: activityID) where order.status == .paid {
            _ = requestRefund(orderID: order.id)
            if CommercePaymentPolicy.simulatesLocalRefundCompletion {
                finalizeRefund(orderID: order.id)
            }
        }
    }

    static func statusLabel(for status: ActivityOrderStatus) -> String {
        switch status {
        case .pending: "待支付"
        case .paid: "已支付"
        case .cancelled: "已取消"
        case .refunding: "退款中"
        case .refunded: "已退款"
        }
    }

    @discardableResult
    static func createPendingOrder(for activity: Activity) -> ActivityOrder? {
        guard let payable = ActivityFeeParser.payableAmount(for: activity) else { return nil }
        let order = ActivityOrder(
            id: UUID(),
            activityID: activity.id,
            activityTitle: activity.title,
            feeDisplay: payable.display,
            amountCents: payable.cents,
            createdAt: .now,
            status: .pending,
            paymentMethod: PaymentMethod.wallet.displayName
        )
        cache.insert(order, at: 0)
        persist()
        return order
    }

    @discardableResult
    static func markPaid(orderID: UUID, method: PaymentMethod = .wallet) -> PaymentOutcome {
        guard let index = cache.firstIndex(where: { $0.id == orderID }) else {
            return .failed("订单不存在")
        }
        // 仅 pending → paid，避免取消后异步任务仍落账
        guard cache[index].status == .pending else {
            return .failed("订单状态已变更")
        }
        if method != .wallet, !CommercePaymentPolicy.allowsSimulatedExternalCheckout {
            return .failed(CommercePaymentPolicy.externalCheckoutUnavailableMessage)
        }
        guard let wallet = requireWallet() else {
            return .failed("支付服务未就绪，请稍后重试")
        }
        let order = cache[index]
        let outcome = wallet.charge(
            amountCents: order.amountCents,
            method: method,
            kind: .activityPayment,
            title: order.activityTitle,
            subtitle: "活动报名",
            relatedID: order.id
        )
        guard outcome == .success else { return outcome }
        cache[index].status = .paid
        cache[index].paymentMethod = method.displayName
        persist()
        if let passStore = requirePassStore() {
            passStore.issueActivityTicket(order: cache[index])
        }
        return .success
    }

    static func cancelPending(orderID: UUID) {
        guard let index = cache.firstIndex(where: { $0.id == orderID }) else { return }
        if cache[index].status == .pending {
            cache[index].status = .cancelled
            persist()
        }
    }

    /// 演示：为「剧本杀：情感本」写入已支付订单并签发 Pass（不扣钱包，仅本地演示）。
    /// 仅 DEBUG 引导路径调用；Release 不得伪造已支付订单。
    @discardableResult
    static func installDemoPaidOrder(
        activity: Activity,
        orderID: UUID,
        passStore: WalletPassStore
    ) -> ActivityOrder {
        #if DEBUG
        if let existing = paidOrder(for: activity.id) {
            _ = passStore.issueActivityTicket(order: existing, activity: activity)
            return existing
        }

        let payable = ActivityFeeParser.payableAmount(for: activity)
            ?? (display: activity.fee, cents: 12_800)
        let order = ActivityOrder(
            id: orderID,
            activityID: activity.id,
            activityTitle: activity.title,
            feeDisplay: payable.display,
            amountCents: payable.cents,
            createdAt: .now,
            status: .paid,
            paymentMethod: PaymentMethod.applePay.displayName
        )
        cache.insert(order, at: 0)
        persist()
        _ = passStore.issueActivityTicket(order: order, activity: activity)
        return order
        #else
        preconditionFailure("installDemoPaidOrder is DEBUG-only")
        #endif
    }

    private static func loadAll() -> [ActivityOrder] {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ActivityOrder].self, from: data)
        else { return [] }
        return decoded
    }

    private static func persist() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: url, options: [.atomic])
        } catch {
            assertionFailure("ActivityPaymentStore persist failed: \(error)")
            PersistenceWriteFailureReporter.record(domainKey: "activityOrders", error: error)
        }
    }

    static func resetAll() {
        cache = []
        persist()
    }
}

struct ActivityPaymentSheet: View {
    let activity: Activity
    var onPaid: () -> Void

    @Environment(WalletPassStore.self) private var walletPassStore
    @State private var order: ActivityOrder?

    private var payable: (display: String, cents: Int)? {
        ActivityFeeParser.payableAmount(for: activity)
    }

    var body: some View {
        CoordinatePaymentSheet(
            navigationTitle: ActivityDetailCopy.paymentTitle,
            summary: [
                ("活动", activity.title),
                ("费用说明", payable?.display ?? activity.fee)
            ],
            amountCents: payable?.cents ?? order?.amountCents ?? 0,
            footer: ActivityDetailCopy.paymentMockHint,
            preferredMethod: .wallet,
                    onConfirm: { method in
                        let ensured = order ?? ActivityPaymentStore.createPendingOrder(for: activity)
                        guard let ensured else { return .failed("无法创建订单") }
                        order = ensured
                        let outcome = ActivityPaymentStore.markPaid(orderID: ensured.id, method: method)
                        if outcome == .success {
                            if let paid = ActivityPaymentStore.order(id: ensured.id) {
                                walletPassStore.issueActivityTicket(order: paid, activity: activity)
                            }
                            onPaid()
                        }
                        return outcome
                    },
            onCancel: {
                if let order {
                    ActivityPaymentStore.cancelPending(orderID: order.id)
                }
            }
        )
        .onAppear {
            if order == nil {
                order = ActivityPaymentStore.createPendingOrder(for: activity)
            }
        }
    }
}

// MARK: - 订单 / 退款

struct ActivityOrdersSheet: View {
    let activityID: Activity.ID?
    var onRefundCompleted: (() -> Void)?

    @Environment(RefundFlowService.self) private var refunds
    @Environment(ActivitiesModel.self) private var activities
    @Environment(\.dismiss) private var dismiss
    @State private var orders: [ActivityOrder] = []
    @State private var refundError: String?
    @State private var refundTarget: ActivityOrder?
    @State private var presentedRefundRequestID: UUID?

    var body: some View {
        NavigationStack {
            List {
                if orders.isEmpty {
                    ContentUnavailableView(
                        ActivityDetailCopy.ordersEmptyTitle,
                        systemImage: "doc.text",
                        description: Text(ActivityDetailCopy.ordersEmptySubtitle)
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(orders) { order in
                        ActivityOrderRow(
                            order: order,
                            refundRequest: refunds.latestRequest(forOrderID: order.id)
                        ) {
                            refundTarget = order
                        }
                    }
                }
            }
            .navigationTitle(ActivityDetailCopy.ordersTitle)
            .navigationBarTitleDisplayMode(.inline)
            .platformSheetConfirmationToolbar()
            .alert("无法退款", isPresented: Binding(
                get: { refundError != nil },
                set: { if !$0 { refundError = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(refundError ?? "")
            }
            .sheet(item: $refundTarget) { order in
                let activity = activities.activity(id: order.activityID)
                let notes = activity.map { ActivityDetailBlueprint.make(for: $0).refundNotes } ?? []
                RefundRequestSheet.activityOrder(order, activity: activity, refundNotes: notes) { reason, detail, _ in
                    beginRefund(order, reason: reason, detail: detail)
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: Binding(
                get: { presentedRefundRequestID != nil },
                set: { if !$0 { presentedRefundRequestID = nil } }
            )) {
                if let requestID = presentedRefundRequestID {
                    RefundStatusSheet(requestID: requestID)
                        .toolbarVisibility(.hidden, for: .tabBar)
                }
            }
            .onAppear(perform: reload)
        }
        .platformSheet(.browser)
    }

    private func reload() {
        if let activityID {
            orders = ActivityPaymentStore.orders(for: activityID)
        } else {
            orders = ActivityPaymentStore.allOrders()
        }
    }

    @discardableResult
    private func beginRefund(_ order: ActivityOrder, reason: String, detail: String) -> Bool {
        let activity = activities.activity(id: order.activityID)
        let notes = activity.map { ActivityDetailBlueprint.make(for: $0).refundNotes } ?? []
        let result = refunds.submitActivityRefund(
            order: order,
            activity: activity,
            refundNotes: notes,
            reason: reason,
            detail: detail,
            cancelRegistration: false
        )
        switch result {
        case .success(let record):
            presentedRefundRequestID = record.id
            reload()
            onRefundCompleted?()
            return true
        case .failure(let error):
            refundError = error.localizedDescription
            return false
        }
    }
}

struct ActivityOrderRow: View {
    let order: ActivityOrder
    var refundRequest: RefundRequestRecord?
    var onRefund: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(order.activityTitle)
                        .font(.subheadline.weight(.semibold))
                    Text(Formatters.conversationListTime(from: order.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Text(ActivityPaymentStore.statusLabel(for: order.status))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .background(statusColor.opacity(0.12), in: Capsule())
            }

            HStack {
                Text(ActivityFeeParser.formattedPrice(cents: order.amountCents))
                    .font(.subheadline.weight(.semibold))
                Text("· \(order.paymentMethod)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if order.status == .paid, refundRequest == nil {
                Button(ActivityDetailCopy.refundCTA, role: .destructive) {
                    onRefund()
                }
                .font(.subheadline.weight(.semibold))
            } else if order.status == .refunding || refundRequest?.status == .submitted || refundRequest?.status == .processing {
                if let refundRequest {
                    Text("\(ActivityDetailCopy.refundProcessing) · \(refundRequest.status.label)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(ActivityDetailCopy.refundProcessing)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if order.status == .refunded {
                Text(ActivityDetailCopy.refundedHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusColor: Color {
        switch order.status {
        case .paid: PlatformStatus.success
        case .pending, .refunding: PlatformStatus.warning
        case .refunded, .cancelled: .secondary
        }
    }
}

struct ActivityDetailOrderBanner: View {
    let order: ActivityOrder
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading) {
                    Text(ActivityDetailCopy.orderBannerTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(ActivityPaymentStore.statusLabel(for: order.status)) · \(ActivityFeeParser.formattedPrice(cents: order.amountCents))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.borderless)
        .accessibilityHint("查看订单")
    }
}
