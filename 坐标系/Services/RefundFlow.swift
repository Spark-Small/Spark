//
//  RefundFlow.swift
//  坐标系
//
//  统一退款申请、策略校验、异步处理与到账闭环（活动 / 陪玩）。
//

import Foundation
import Observation

// MARK: - Models

enum RefundRequestKind: String, Codable, Hashable {
    case activity
    case booking
}

enum RefundRequestStatus: String, Codable, Hashable, CaseIterable {
    case submitted
    case processing
    case completed
    case rejected

    var label: String {
        switch self {
        case .submitted: "已提交"
        case .processing: "处理中"
        case .completed: "已完成"
        case .rejected: "已拒绝"
        }
    }
}

enum RefundInitiator: String, Codable, Hashable {
    case user
    case system
}

struct RefundRequestRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: RefundRequestKind
    /// 关联 ActivityOrder.id 或 BuddyBookingRecord.id
    let orderID: UUID
    let subjectTitle: String
    let amountCents: Int
    let amountDisplay: String
    let paymentMethod: String
    var reason: String
    var detail: String
    var status: RefundRequestStatus
    let initiator: RefundInitiator
    let createdAt: Date
    var processingStartedAt: Date?
    var completedAt: Date?
    /// 活动退款完成后是否取消参加
    var cancelsRegistration: Bool
    var activityID: UUID?
    var rejectionMessage: String?
}

enum RefundSubmitError: LocalizedError {
    case policyDenied(String)
    case orderNotRefundable
    case duplicateInFlight
    case orderNotFound
    case bookingNotFound

    var errorDescription: String? {
        switch self {
        case .policyDenied(let message): message
        case .orderNotRefundable: "当前订单不可退款"
        case .duplicateInFlight: "该订单已有退款申请在处理中"
        case .orderNotFound: "订单不存在"
        case .bookingNotFound: "预约不存在"
        }
    }
}

// MARK: - Policy

enum RefundPolicy {
    struct Evaluation: Hashable {
        let allowed: Bool
        let headline: String
        let detail: String
    }

    static func evaluateActivity(activity: Activity, refundNotes: [String]) -> Evaluation {
        let now = Date.now
        if activity.date <= now {
            return Evaluation(
                allowed: false,
                headline: "活动已开始",
                detail: "活动已开始或已结束，无法在线申请退款。如有争议请联系客服。"
            )
        }

        let hoursUntil = activity.date.timeIntervalSince(now) / 3600
        if hoursUntil < 6 {
            return Evaluation(
                allowed: false,
                headline: "临近开始不可退",
                detail: "活动开始前 6 小时内不支持在线退款。如有特殊情况请联系发起人协商。"
            )
        }

        let noteText = refundNotes.isEmpty
            ? "活动开始前 6 小时可全额退款；提交后需再次确认。"
            : refundNotes.joined(separator: "；")
        return Evaluation(
            allowed: true,
            headline: "可全额退款",
            detail: noteText
        )
    }

    static func evaluateBooking(record: BuddyBookingRecord) -> Evaluation {
        guard record.canRefund else {
            return Evaluation(
                allowed: false,
                headline: "当前不可退",
                detail: "仅已支付或进行中的预约可申请退款。"
            )
        }
        let now = Date.now
        if record.endAt <= now {
            return Evaluation(
                allowed: false,
                headline: "履约已结束",
                detail: "预约时段已结束，请通过「完成订单」或联系客服处理。"
            )
        }
        let hoursUntil = record.scheduledAt.timeIntervalSince(now) / 3600
        if hoursUntil < 2 {
            return Evaluation(
                allowed: true,
                headline: "临近开始仍可退",
                detail: "距开始不足 2 小时，提交后将尽快处理；演示环境按原支付方式退回。"
            )
        }
        return Evaluation(
            allowed: true,
            headline: "可全额退款",
            detail: "开始前 2 小时外可全额退款；提交后需再次确认。"
        )
    }

    /// 系统发起（主办取消、库存失败等）始终允许
    static let systemAllowed = Evaluation(
        allowed: true,
        headline: "系统自动退款",
        detail: "因活动变更或报名失败，系统将按原支付方式退回。"
    )
}

// MARK: - Copy

enum RefundFlowCopy {
    static let statusNavigationTitle = "退款进度"
    static let submittedHint = "申请已提交，正在排队处理"
    static let processingHint = "退款处理中，请稍候"
    static let completedHint = "退款已完成"
    static let rejectedHint = "退款未通过"
    static let viewWallet = "查看钱包"
    static let done = "完成"
    static let timelineTitle = "处理进度"
    static let reasonSection = "申请信息"
    static let orderSection = "订单信息"
    static let expeditedNote = "系统正在优先处理"

    static func completedMessage(amountDisplay: String, method: PaymentMethod) -> String {
        if method.affectsWalletBalance {
            return "\(amountDisplay) 已退回钱包余额"
        }
        return "\(amountDisplay) 将原路退回 \(method.displayName)，演示环境即时到账"
    }
}

// MARK: - Service

@MainActor
@Observable
final class RefundFlowService {
    static let shared = RefundFlowService()

    private static let fileName = "refund_requests.json"
    private(set) var requests: [RefundRequestRecord] = []
    private var processingTasks: [UUID: Task<Void, Never>] = [:]

    private init() {
        requests = Self.loadAll().sorted { $0.createdAt > $1.createdAt }
    }

    func request(id: UUID) -> RefundRequestRecord? {
        requests.first { $0.id == id }
    }

    func latestRequest(forOrderID orderID: UUID) -> RefundRequestRecord? {
        requests.first { $0.orderID == orderID }
    }

    func isRefunding(orderID: UUID) -> Bool {
        guard let record = latestRequest(forOrderID: orderID) else { return false }
        return record.status == .submitted || record.status == .processing
    }

    // MARK: Submit — Activity

    @discardableResult
    func submitActivityRefund(
        order: ActivityOrder,
        activity: Activity?,
        refundNotes: [String] = [],
        reason: String,
        detail: String,
        cancelRegistration: Bool,
        initiator: RefundInitiator = .user,
        expedited: Bool = false,
        onCancelRegistration: ((Activity.ID) -> Void)? = nil
    ) -> Result<RefundRequestRecord, RefundSubmitError> {
        if isRefunding(orderID: order.id) {
            return .failure(.duplicateInFlight)
        }

        if initiator == .user {
            if order.status != .paid {
                return .failure(.orderNotRefundable)
            }
            if let activity {
                let policy = RefundPolicy.evaluateActivity(activity: activity, refundNotes: refundNotes)
                guard policy.allowed else {
                    return .failure(.policyDenied(policy.detail))
                }
            }
        } else if order.status != .paid && order.status != .refunding {
            return .failure(.orderNotRefundable)
        }

        if order.status == .paid {
            if let error = ActivityPaymentStore.requestRefund(orderID: order.id) {
                return .failure(.policyDenied(error))
            }
        }

        let record = RefundRequestRecord(
            id: UUID(),
            kind: .activity,
            orderID: order.id,
            subjectTitle: order.activityTitle,
            amountCents: order.amountCents,
            amountDisplay: ActivityFeeParser.formattedPrice(cents: order.amountCents),
            paymentMethod: order.paymentMethod,
            reason: reason,
            detail: detail,
            status: .submitted,
            initiator: initiator,
            createdAt: .now,
            processingStartedAt: nil,
            completedAt: nil,
            cancelsRegistration: cancelRegistration,
            activityID: order.activityID,
            rejectionMessage: nil
        )
        insert(record)
        enqueueProcessing(recordID: record.id, expedited: expedited) {
            if cancelRegistration {
                onCancelRegistration?(order.activityID)
            }
        }
        return .success(record)
    }

    /// 主办取消活动：为所有已支付订单创建系统退款
    func submitSystemActivityRefunds(
        for activityID: Activity.ID,
        activityTitle: String,
        refundNotes: [String] = [],
        onCancelRegistration: ((Activity.ID) -> Void)? = nil
    ) {
        for order in ActivityPaymentStore.orders(for: activityID) where order.status == .paid {
            _ = submitActivityRefund(
                order: order,
                activity: nil,
                refundNotes: refundNotes,
                reason: "主办取消活动",
                detail: "活动「\(activityTitle)」已被发起人取消，系统自动退款。",
                cancelRegistration: false,
                initiator: .system,
                expedited: true,
                onCancelRegistration: onCancelRegistration
            )
        }
    }

    /// 支付成功但报名失败等场景：系统即时退款，不取消参加（尚未加入）
    func submitExpeditedActivityRefund(
        order: ActivityOrder,
        reason: String,
        detail: String
    ) -> Result<RefundRequestRecord, RefundSubmitError> {
        submitActivityRefund(
            order: order,
            activity: nil,
            reason: reason,
            detail: detail,
            cancelRegistration: false,
            initiator: .system,
            expedited: true
        )
    }

    // MARK: Submit — Booking

    @discardableResult
    func submitBookingRefund(
        record: BuddyBookingRecord,
        reason: String,
        detail: String,
        initiator: RefundInitiator = .user,
        expedited: Bool = false,
        onFinalize: @escaping (BuddyBookingRecord.ID) -> Void = { _ in }
    ) -> Result<RefundRequestRecord, RefundSubmitError> {
        if isRefunding(orderID: record.id) {
            return .failure(.duplicateInFlight)
        }

        if initiator == .user {
            let policy = RefundPolicy.evaluateBooking(record: record)
            guard policy.allowed else {
                return .failure(.policyDenied(policy.detail))
            }
            guard record.canRefund else {
                return .failure(.orderNotRefundable)
            }
        }

        let amountCents = WalletMoney.cents(fromDisplay: record.priceText)
            ?? max(record.hours, 1) * 6_800

        let refundRecord = RefundRequestRecord(
            id: UUID(),
            kind: .booking,
            orderID: record.id,
            subjectTitle: record.companionNickname,
            amountCents: amountCents,
            amountDisplay: record.priceText,
            paymentMethod: record.paymentMethod,
            reason: reason,
            detail: detail,
            status: .submitted,
            initiator: initiator,
            createdAt: .now,
            processingStartedAt: nil,
            completedAt: nil,
            cancelsRegistration: false,
            activityID: nil,
            rejectionMessage: nil
        )
        insert(refundRecord)
        bookingFinalizeHandlers[refundRecord.id] = onFinalize
        enqueueProcessing(recordID: refundRecord.id, expedited: expedited) {}
        return .success(refundRecord)
    }

    private var bookingFinalizeHandlers: [UUID: (BuddyBookingRecord.ID) -> Void] = [:]

    func resetAll() {
        processingTasks.values.forEach { $0.cancel() }
        processingTasks.removeAll()
        bookingFinalizeHandlers.removeAll()
        requests = []
        persist()
    }

    // MARK: Private

    private func insert(_ record: RefundRequestRecord) {
        requests.insert(record, at: 0)
        persist()
    }

    private func update(_ record: RefundRequestRecord) {
        guard let index = requests.firstIndex(where: { $0.id == record.id }) else { return }
        requests[index] = record
        persist()
    }

    private func enqueueProcessing(
        recordID: UUID,
        expedited: Bool,
        onActivityCancelled: @escaping () -> Void
    ) {
        processingTasks[recordID]?.cancel()
        processingTasks[recordID] = Task { @MainActor in
            let delay: Duration = expedited ? .milliseconds(350) : .milliseconds(900)
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }

            guard var record = request(id: recordID) else { return }
            record.status = .processing
            record.processingStartedAt = .now
            update(record)

            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }

            finalize(recordID: recordID, onActivityCancelled: onActivityCancelled)
            processingTasks[recordID] = nil
        }
    }

    private func finalize(
        recordID: UUID,
        onActivityCancelled: @escaping () -> Void
    ) {
        guard var record = request(id: recordID) else { return }
        guard record.status == .processing || record.status == .submitted else { return }

        switch record.kind {
        case .activity:
            finalizeActivity(&record, onActivityCancelled: onActivityCancelled)
        case .booking:
            finalizeBooking(&record)
        }

        record.status = .completed
        record.completedAt = .now
        update(record)
    }

    private func finalizeActivity(
        _ record: inout RefundRequestRecord,
        onActivityCancelled: () -> Void
    ) {
        ActivityPaymentStore.finalizeRefund(orderID: record.orderID)
        TrustService.shared.record(
            .activityRefunded,
            domain: .activity,
            actorKey: trustActorKey(),
            subjectKey: record.subjectTitle,
            note: record.reason
        )
        if record.cancelsRegistration {
            onActivityCancelled()
        }
    }

    private func finalizeBooking(_ record: inout RefundRequestRecord) {
        let method = PaymentMethod.resolve(record.paymentMethod)
        WalletStore.shared.credit(
            amountCents: record.amountCents,
            method: method,
            kind: .bookingRefund,
            title: "陪玩退款 · \(record.subjectTitle)",
            subtitle: record.amountDisplay,
            relatedID: record.orderID
        )
        NotificationService.cancelBookingReminder(bookingID: record.orderID)
        WalletPassStore.shared.void(relatedID: record.orderID)
        TrustService.shared.record(
            .bookingRefunded,
            domain: .booking,
            actorKey: trustActorKey(),
            subjectKey: record.subjectTitle,
            note: record.reason
        )
        bookingFinalizeHandlers[record.id]?(record.orderID)
        bookingFinalizeHandlers.removeValue(forKey: record.id)
    }

    private func trustActorKey() -> String {
        LocalUserIdentity.current.uuidString
    }

    private static func loadAll() -> [RefundRequestRecord] {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([RefundRequestRecord].self, from: data)
        else { return [] }
        return decoded
    }

    private func persist() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.fileName)
        guard let data = try? JSONEncoder().encode(requests) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
