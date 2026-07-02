// Module: SparkBuddy — Provider earnings summary (approved companions only).

import Foundation

public struct BuddyProviderEarnings: Equatable, Sendable {
    public let availableBalance: Decimal
    public let pendingEscrow: Decimal
    public let currencyCode: String
    public let completedOrderCount: Int
    public let monthEarnings: Decimal

    public init(
        availableBalance: Decimal,
        pendingEscrow: Decimal,
        currencyCode: String,
        completedOrderCount: Int,
        monthEarnings: Decimal
    ) {
        self.availableBalance = availableBalance
        self.pendingEscrow = pendingEscrow
        self.currencyCode = currencyCode
        self.completedOrderCount = completedOrderCount
        self.monthEarnings = monthEarnings
    }
}

public struct BuddyProviderOrder: Identifiable, Equatable, Sendable {
    public let id: String
    public let guestDisplayName: String
    public let packageTitle: String
    public let scheduledAt: Date
    public let amount: Decimal
    public let currencyCode: String
    public let state: BuddyProviderOrderState

    public init(
        id: String,
        guestDisplayName: String,
        packageTitle: String,
        scheduledAt: Date,
        amount: Decimal,
        currencyCode: String,
        state: BuddyProviderOrderState
    ) {
        self.id = id
        self.guestDisplayName = guestDisplayName
        self.packageTitle = packageTitle
        self.scheduledAt = scheduledAt
        self.amount = amount
        self.currencyCode = currencyCode
        self.state = state
    }
}

public enum BuddyProviderOrderState: String, Sendable, Equatable {
    case upcoming
    case inProgress
    case completed
    case cancelled

    public var localizedTitle: String {
        switch self {
        case .upcoming:
            String(localized: "buddy.provider.order.upcoming", defaultValue: "待服务", comment: "Upcoming order")
        case .inProgress:
            String(localized: "buddy.provider.order.inProgress", defaultValue: "进行中", comment: "In progress order")
        case .completed:
            String(localized: "buddy.provider.order.completed", defaultValue: "已完成", comment: "Completed order")
        case .cancelled:
            String(localized: "buddy.provider.order.cancelled", defaultValue: "已取消", comment: "Cancelled order")
        }
    }
}
