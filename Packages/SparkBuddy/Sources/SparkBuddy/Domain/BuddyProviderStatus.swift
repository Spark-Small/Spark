// Module: SparkBuddy — Companion (陪玩) provider onboarding status.

import Foundation

/// Provider approval gate for earnings and host-side surfaces.
public enum BuddyProviderApprovalState: String, Sendable, Equatable, Codable {
    case none
    case pending
    case approved
    case rejected
    case suspended
}

public struct BuddyProviderStatus: Equatable, Sendable {
    public let state: BuddyProviderApprovalState
    public let submittedAt: Date?
    public let reviewedAt: Date?
    public let rejectionReason: String?

    public init(
        state: BuddyProviderApprovalState,
        submittedAt: Date? = nil,
        reviewedAt: Date? = nil,
        rejectionReason: String? = nil
    ) {
        self.state = state
        self.submittedAt = submittedAt
        self.reviewedAt = reviewedAt
        self.rejectionReason = rejectionReason
    }

    public var canAccessEarnings: Bool {
        state == .approved
    }

    public var localizedTitle: String {
        switch state {
        case .none:
            String(
                localized: "buddy.provider.status.none",
                defaultValue: "未申请",
                comment: "Provider not applied"
            )
        case .pending:
            String(
                localized: "buddy.provider.status.pending",
                defaultValue: "审核中",
                comment: "Provider pending review"
            )
        case .approved:
            String(
                localized: "buddy.provider.status.approved",
                defaultValue: "已认证陪玩",
                comment: "Provider approved"
            )
        case .rejected:
            String(
                localized: "buddy.provider.status.rejected",
                defaultValue: "未通过",
                comment: "Provider rejected"
            )
        case .suspended:
            String(
                localized: "buddy.provider.status.suspended",
                defaultValue: "已暂停",
                comment: "Provider suspended"
            )
        }
    }
}
