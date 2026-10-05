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

    /// 详情 / 行程商务条：待支付优先，其次已支付，再次退款态。
    static func displayOrder(for activityID: Activity.ID) -> ActivityOrder? {
        orders(for: activityID).first { $0.status == .pending }
            ?? paidOrder(for: activityID)
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
    static func markPaid(orderID: UUID, method: PaymentMethod = .wallet) async -> PaymentOutcome {
        guard let index = cache.firstIndex(where: { $0.id == orderID }) else {
            return .failed("订单不存在")
        }
        // 仅 pending → paid，避免取消后异步任务仍落账
        guard cache[index].status == .pending else {
            return .failed("订单状态已变更")
        }
        if method != .wallet, !CommercePaymentPolicy.allowsSimulatedExternalCheckout {
            CommerceAnalytics.checkoutBlocked(method: method.rawValue)
            return .failed(CommercePaymentPolicy.externalCheckoutUnavailableMessage)
        }
        guard let wallet = requireWallet() else {
            return .failed("支付服务未就绪，请稍后重试")
        }
        let order = cache[index]
        let outcome = await wallet.chargeAsync(
            amountCents: order.amountCents,
            method: method,
            kind: .activityPayment,
            title: order.activityTitle,
            subtitle: "活动报名",
            relatedID: order.id,
            orderType: "activity"
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
