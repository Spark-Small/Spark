import Foundation

public enum BookingOrderStatus: String, Codable, Hashable, CaseIterable, Sendable {
    /// 已下单，等待陪玩确认接单
    case pendingConfirm = "待确认"
    /// 对方已接单，等待用户支付
    case awaitingPayment = "待支付"
    case paid = "已支付"
    case inProgress = "进行中"
    case completed = "已完成"
    case refunding = "退款中"
    case refunded = "已退款"
    case cancelled = "已取消"
}

public enum BuddyInviteStatus: String, Codable, Hashable, CaseIterable, Sendable {
    case pending = "待回执"
    case accepted = "已接受"
    case declined = "已婉拒"
}

public struct BuddyInviteRecord: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var nickname: String
    public var activityTitle: String
    public var sentAt: Date
    public var status: BuddyInviteStatus
    /// 绑活动 id，接受后进群用
    public var relatedActivityID: UUID?

    public init(
        id: UUID,
        nickname: String,
        activityTitle: String,
        sentAt: Date,
        status: BuddyInviteStatus = .pending,
        relatedActivityID: UUID? = nil
    ) {
        self.id = id
        self.nickname = nickname
        self.activityTitle = activityTitle
        self.sentAt = sentAt
        self.status = status
        self.relatedActivityID = relatedActivityID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        nickname = try container.decode(String.self, forKey: .nickname)
        activityTitle = try container.decode(String.self, forKey: .activityTitle)
        sentAt = try container.decode(Date.self, forKey: .sentAt)
        status = try container.decodeIfPresent(BuddyInviteStatus.self, forKey: .status) ?? .accepted
        relatedActivityID = try container.decodeIfPresent(UUID.self, forKey: .relatedActivityID)
    }
}

public struct BuddyBookingRecord: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var companionNickname: String
    public var hours: Int
    public var scheduledAt: Date
    public var bookedAt: Date
    public var priceText: String
    public var status: BookingOrderStatus
    /// 等待陪玩接单的截止；超时自动取消（B-30）。
    public var confirmDueAt: Date?
    public var paymentMethod: String
    public var paidAt: Date?
    public var completedAt: Date?
    /// 陪玩接单时间；进入 `awaitingPayment` 时写入。
    public var acceptedAt: Date?
    /// 待支付截止；超时后自动释放订单。
    public var paymentDueAt: Date?
    /// 用户点选的档期文案（演示）
    public var selectedSlotLabel: String?
    /// 进入 `refunding` 前的履约态，供退款拒绝时恢复
    public var refundRestoreStatus: BookingOrderStatus?

    public init(
        id: UUID,
        companionNickname: String,
        hours: Int,
        scheduledAt: Date,
        bookedAt: Date,
        priceText: String,
        status: BookingOrderStatus = .pendingConfirm,
        confirmDueAt: Date? = nil,
        paymentMethod: String = "simulated",
        paidAt: Date? = nil,
        completedAt: Date? = nil,
        acceptedAt: Date? = nil,
        paymentDueAt: Date? = nil,
        selectedSlotLabel: String? = nil,
        refundRestoreStatus: BookingOrderStatus? = nil
    ) {
        self.id = id
        self.companionNickname = companionNickname
        self.hours = hours
        self.scheduledAt = scheduledAt
        self.bookedAt = bookedAt
        self.priceText = priceText
        self.status = status
        self.confirmDueAt = confirmDueAt
        self.paymentMethod = paymentMethod
        self.paidAt = paidAt
        self.completedAt = completedAt
        self.acceptedAt = acceptedAt
        self.paymentDueAt = paymentDueAt
        self.selectedSlotLabel = selectedSlotLabel
        self.refundRestoreStatus = refundRestoreStatus
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        companionNickname = try container.decode(String.self, forKey: .companionNickname)
        hours = try container.decode(Int.self, forKey: .hours)
        scheduledAt = try container.decode(Date.self, forKey: .scheduledAt)
        bookedAt = try container.decode(Date.self, forKey: .bookedAt)
        priceText = try container.decode(String.self, forKey: .priceText)
        status = try container.decodeIfPresent(BookingOrderStatus.self, forKey: .status) ?? .pendingConfirm
        confirmDueAt = try container.decodeIfPresent(Date.self, forKey: .confirmDueAt)
        paymentMethod = try container.decodeIfPresent(String.self, forKey: .paymentMethod) ?? "simulated"
        paidAt = try container.decodeIfPresent(Date.self, forKey: .paidAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        acceptedAt = try container.decodeIfPresent(Date.self, forKey: .acceptedAt)
        paymentDueAt = try container.decodeIfPresent(Date.self, forKey: .paymentDueAt)
        selectedSlotLabel = try container.decodeIfPresent(String.self, forKey: .selectedSlotLabel)
        refundRestoreStatus = try container.decodeIfPresent(BookingOrderStatus.self, forKey: .refundRestoreStatus)
    }

    public var endAt: Date {
        scheduledAt.addingTimeInterval(TimeInterval(hours * 3600))
    }

    public var statusLabel: String { status.rawValue }

    public var canPay: Bool { status == .awaitingPayment }

    public var canSimulateCounterpart: Bool { status == .pendingConfirm }

    public var canMarkInProgress: Bool { status == .paid }

    public var canComplete: Bool { status == .paid || status == .inProgress }

    public var canRefund: Bool {
        guard status == .paid || status == .inProgress else { return false }
        return endAt > .now
    }

    public var canReschedule: Bool {
        switch status {
        case .pendingConfirm, .awaitingPayment, .paid, .inProgress: true
        case .completed, .refunding, .refunded, .cancelled: false
        }
    }

    public var canWithdraw: Bool {
        status == .pendingConfirm || status == .awaitingPayment
    }

    public func isPaymentOverdue(at now: Date = .now) -> Bool {
        guard status == .awaitingPayment, let paymentDueAt else { return false }
        return now >= paymentDueAt
    }

    public func paymentTimeRemaining(at now: Date = .now) -> TimeInterval? {
        guard status == .awaitingPayment, let paymentDueAt else { return nil }
        return max(paymentDueAt.timeIntervalSince(now), 0)
    }

    public func isConfirmationOverdue(at now: Date = .now) -> Bool {
        guard status == .pendingConfirm, let confirmDueAt else { return false }
        return now >= confirmDueAt
    }

    public func confirmationTimeRemaining(at now: Date = .now) -> TimeInterval? {
        guard status == .pendingConfirm, let confirmDueAt else { return nil }
        return max(confirmDueAt.timeIntervalSince(now), 0)
    }
}
