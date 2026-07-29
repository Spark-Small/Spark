//
//  ActivityPaymentFlow.swift
//  坐标系
//
//  本地模拟支付流程（无真实后端）：下单 → 确认支付 → 参加。
//

import Foundation
import SwiftUI

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
    private static let fileName = "activity_orders.json"
    private static var cache: [ActivityOrder] = loadAll()

    static func orders(for activityID: Activity.ID) -> [ActivityOrder] {
        cache.filter { $0.activityID == activityID }.sorted { $0.createdAt > $1.createdAt }
    }

    static func paidOrder(for activityID: Activity.ID) -> ActivityOrder? {
        orders(for: activityID).first { $0.status == .paid }
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
        cache[index].status = .refunded
        persist()
    }

    /// 主办取消活动时，批量演示退款已支付订单
    static func refundAllPaidOrders(for activityID: Activity.ID) {
        for order in orders(for: activityID) where order.status == .paid {
            _ = requestRefund(orderID: order.id)
            finalizeRefund(orderID: order.id)
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
            paymentMethod: "Apple Pay"
        )
        cache.insert(order, at: 0)
        persist()
        return order
    }

    @discardableResult
    static func markPaid(orderID: UUID, method: String = "Apple Pay") -> Bool {
        guard let index = cache.firstIndex(where: { $0.id == orderID }) else { return false }
        // 仅 pending → paid，避免取消后异步任务仍落账
        guard cache[index].status == .pending else { return false }
        cache[index].status = .paid
        cache[index].paymentMethod = method
        persist()
        return true
    }

    static func cancelPending(orderID: UUID) {
        guard let index = cache.firstIndex(where: { $0.id == orderID }) else { return }
        if cache[index].status == .pending {
            cache[index].status = .cancelled
            persist()
        }
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
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    static func resetAll() {
        cache = []
        persist()
    }
}

struct ActivityPaymentSheet: View {
    let activity: Activity
    var onPaid: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var order: ActivityOrder?
    @State private var isProcessing = false
    @State private var selectedMethod = "Apple Pay"
    /// 可取消的支付 Task（Swift 并发官方模式）
    @State private var paymentTask: Task<Void, Never>?

    private var payable: (display: String, cents: Int)? {
        ActivityFeeParser.payableAmount(for: activity)
    }

    var body: some View {
        NavigationStack {
            List {
                if let payable {
                    Section {
                        LabeledContent("活动") {
                            Text(activity.title)
                                .multilineTextAlignment(.trailing)
                        }
                        LabeledContent("费用说明") {
                            Text(payable.display)
                        }
                        LabeledContent("应付金额") {
                            Text(ActivityFeeParser.formattedPrice(cents: payable.cents))
                                .fontWeight(.bold)
                        }
                    } footer: {
                        Text(ActivityDetailCopy.paymentMockHint)
                    }

                    Section("支付方式") {
                        Picker("支付方式", selection: $selectedMethod) {
                            Text("Apple Pay").tag("Apple Pay")
                            Text("微信支付").tag("微信支付")
                            Text("支付宝").tag("支付宝")
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                        .disabled(isProcessing)
                    }
                }
            }
            .navigationTitle(ActivityDetailCopy.paymentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        cancelPaymentFlow()
                    }
                    .disabled(isProcessing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActivityDetailCopy.paymentTitle) {
                        processPayment()
                    }
                    .fontWeight(.semibold)
                    .disabled(isProcessing || payable == nil)
                }
            }
            .overlay {
                if isProcessing {
                    ProgressView(ActivityDetailCopy.paymentProcessing)
                        .platformProcessingOverlayChrome()
                }
            }
            .onAppear {
                if order == nil {
                    order = ActivityPaymentStore.createPendingOrder(for: activity)
                }
            }
            .onDisappear {
                paymentTask?.cancel()
                paymentTask = nil
            }
        }
        .platformSheet(.browser, interactiveDismissDisabled: isProcessing)
    }

    private func cancelPaymentFlow() {
        paymentTask?.cancel()
        paymentTask = nil
        isProcessing = false
        if let order { ActivityPaymentStore.cancelPending(orderID: order.id) }
        dismiss()
    }

    private func processPayment() {
        guard let order, !isProcessing else { return }
        isProcessing = true
        paymentTask?.cancel()
        paymentTask = Task { @MainActor in
            // 模拟网关延迟；取消时 Task.isCancelled 为 true
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled else { return }

            let paid = ActivityPaymentStore.markPaid(orderID: order.id, method: selectedMethod)
            isProcessing = false
            paymentTask = nil
            guard paid else { return }

            onPaid()
            dismiss()
        }
    }
}

// MARK: - 订单 / 退款

struct ActivityOrdersSheet: View {
    let activityID: Activity.ID?
    var onRefundCompleted: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var orders: [ActivityOrder] = []
    @State private var refundingID: UUID?
    @State private var refundError: String?

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
                        ActivityOrderRow(order: order) {
                            beginRefund(order)
                        }
                        .disabled(refundingID != nil)
                    }
                }
            }
            .navigationTitle(ActivityDetailCopy.ordersTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .overlay {
                if refundingID != nil {
                    ProgressView(ActivityDetailCopy.refundProcessing)
                        .platformProcessingOverlayChrome()
                }
            }
            .alert("无法退款", isPresented: Binding(
                get: { refundError != nil },
                set: { if !$0 { refundError = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(refundError ?? "")
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

    private func beginRefund(_ order: ActivityOrder) {
        if let error = ActivityPaymentStore.requestRefund(orderID: order.id) {
            refundError = error
            return
        }
        refundingID = order.id
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            ActivityPaymentStore.finalizeRefund(orderID: order.id)
            refundingID = nil
            reload()
            onRefundCompleted?()
        }
    }
}

struct ActivityOrderRow: View {
    let order: ActivityOrder
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

            if order.status == .paid {
                Button(ActivityDetailCopy.refundCTA, role: .destructive) {
                    onRefund()
                }
                .font(.subheadline.weight(.semibold))
            } else if order.status == .refunding {
                Text(ActivityDetailCopy.refundProcessing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
