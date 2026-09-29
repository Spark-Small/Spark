//
//  TrustModels.swift
//  坐标系
//
//  行为信用领域模型（详见 Docs/TrustBehaviorModel.md）。
//

import Foundation
import CoordinateModels

// MARK: - Events

enum TrustDomain: String, Codable, CaseIterable {
    case account
    case activity
    case buddy
    case booking
    case social
    case community
    case org
    case wallet
    case moderation
}

enum TrustEventName: String, Codable, CaseIterable {
    // account
    case guestContinue = "guest_continue"
    case accountCreated = "account_created"
    case signOut = "sign_out"
    case accountDeleted = "account_deleted"
    case onboardingCompleted = "onboarding_completed"
    case profileCompletionChanged = "profile_completion_changed"
    case privacyChanged = "privacy_changed"
    case youthModeChanged = "youth_mode_changed"

    // activity
    case activityJoined = "joined"
    case activityLeft = "left"
    case activityHosted = "hosted_published"
    case activityHostCancelled = "host_cancelled"
    case activityPaid = "order_paid"
    case activityRefunded = "order_refunded"

    // buddy / booking
    case inviteSent = "invite_sent"
    case inviteAccepted = "invite_accepted"
    case inviteDeclined = "invite_declined"
    case bookingCreated = "booking_created"
    case bookingAccepted = "booking_accepted"
    case bookingDeclined = "booking_declined"
    case bookingRescheduled = "booking_rescheduled"
    case bookingPaid = "booking_paid"
    case bookingCompleted = "booking_completed"
    case bookingCancelled = "booking_cancelled"
    case bookingRefunded = "booking_refunded"
    case safetyCheckinOK = "safety_checkin_ok"
    case safetyCheckinIssue = "safety_checkin_issue"

    // social / moderation
    case blocked = "blocked"
    case unblocked = "unblocked"
    case personReported = "person_reported"
    case ticketResolvedAgainst = "ticket_resolved_against"
    case mediaBlocked = "media_blocked"
    case identityFailed = "identity_failed"
    case identityRemoteVerified = "identity_remote_verified"

    // wallet
    case membershipActivated = "membership_activated"
    case topUp = "top_up"
}

struct TrustBehaviorEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    let actorKey: String
    var subjectKey: String?
    let domain: TrustDomain
    let name: TrustEventName
    /// 可选幅度，默认 1
    var value: Double
    var note: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        actorKey: String,
        subjectKey: String? = nil,
        domain: TrustDomain,
        name: TrustEventName,
        value: Double = 1,
        note: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.actorKey = actorKey
        self.subjectKey = subjectKey
        self.domain = domain
        self.name = name
        self.value = value
        self.note = note
    }
}

// MARK: - Level & axes

enum TrustLevel: String, Codable, Hashable {
    case guest
    case newcomer
    case trusted
    case reliableHost
    case restricted

    var title: String {
        switch self {
        case .guest: "浏览中"
        case .newcomer: "新伙伴"
        case .trusted: "可信"
        case .reliableHost: "靠谱发起人"
        case .restricted: "受限"
        }
    }

    var systemImage: String {
        switch self {
        case .guest: "person.crop.circle"
        case .newcomer: "leaf"
        case .trusted: "checkmark.shield"
        case .reliableHost: "flag.checkered"
        case .restricted: "exclamationmark.shield"
        }
    }
}

/// 内部行为健康轴 0…100（自查用，不是他人打星）。
struct TrustAxisScores: Hashable {
    var identity: Double
    var reliability: Double
    var communication: Double
    var safety: Double

    static var labels: [(KeyPath<TrustAxisScores, Double>, String)] {
        [
            (\.identity, "身份"),
            (\.reliability, "守约"),
            (\.communication, "沟通"),
            (\.safety, "安全")
        ]
    }

    var overall: Double {
        // 守约与安全权重大
        (identity * 0.2 + reliability * 0.35 + communication * 0.2 + safety * 0.25)
    }
}

// MARK: - Badges

enum TrustBadgeKind: String, Codable, CaseIterable, Identifiable {
    case photoVerified
    case phoneVerified
    case identityVerified
    case activeMember
    case reliableHost
    case trustedNeighbor

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photoVerified: "认证"
        case .phoneVerified: "手机已验证"
        case .identityVerified: "实名认证"
        case .activeMember: "会员"
        case .reliableHost: "靠谱发起人"
        case .trustedNeighbor: "可信伙伴"
        }
    }

    var systemImage: String {
        switch self {
        case .photoVerified: "checkmark.seal.fill"
        case .phoneVerified: "phone.badge.checkmark"
        case .identityVerified: "person.text.rectangle"
        case .activeMember: "crown.fill"
        case .reliableHost: "flag.checkered"
        case .trustedNeighbor: "hand.thumbsup.circle.fill"
        }
    }
}

struct TrustBadge: Identifiable, Hashable {
    let kind: TrustBadgeKind
    var id: String { kind.id }
    var title: String { kind.title }
    var systemImage: String { kind.systemImage }
}

struct TrustVerification: Hashable {
    var photoVerified: Bool
    var phoneVerified: Bool
    var identityVerified: Bool

    var badges: [TrustBadge] {
        var list: [TrustBadge] = []
        if photoVerified { list.append(TrustBadge(kind: .photoVerified)) }
        if phoneVerified { list.append(TrustBadge(kind: .phoneVerified)) }
        if identityVerified { list.append(TrustBadge(kind: .identityVerified)) }
        return list
    }

    static let none = TrustVerification(
        photoVerified: false,
        phoneVerified: false,
        identityVerified: false
    )
}

// MARK: - Facts & cards

struct TrustBehaviorFacts: Hashable {
    var accountAgeDays: Int
    var joinedKept: Int
    var joinedTotal: Int
    var hostedCompletedLike: Int
    var hostedCancelled: Int
    var bookingsCompleted: Int
    var bookingsCancelledOrRefunded: Int
    var eventCount90d: Int

    var joinFulfillmentText: String {
        guard joinedTotal > 0 else { return "近 90 天暂无参加记录" }
        return "近 90 天参加履约 \(joinedKept)/\(joinedTotal)"
    }

    var hostFulfillmentText: String? {
        let total = hostedCompletedLike + hostedCancelled
        guard total > 0 else { return nil }
        let rate = Int((Double(hostedCompletedLike) / Double(total) * 100).rounded())
        return "发起履约 \(rate)%"
    }

    var bookingText: String? {
        let total = bookingsCompleted + bookingsCancelledOrRefunded
        guard total > 0 else { return nil }
        return "陪玩完成 \(bookingsCompleted) · 取消/退款 \(bookingsCancelledOrRefunded)"
    }

    var publicFactLines: [String] {
        var lines = [joinFulfillmentText]
        if let host = hostFulfillmentText { lines.append(host) }
        if accountAgeDays > 0 { lines.append("账号 \(accountAgeDays) 天") }
        return lines
    }
}

struct TrustPublicCard: Hashable {
    let nickname: String
    let level: TrustLevel
    let badges: [TrustBadge]
    let facts: TrustBehaviorFacts
    let factLines: [String]
    let responseHint: String?
    let confidenceLow: Bool
}

struct TrustPrivateStatus: Hashable {
    let score: Int
    let level: TrustLevel
    let axes: TrustAxisScores
    let badges: [TrustBadge]
    let facts: TrustBehaviorFacts
    let growthTips: [String]
    let safetyTips: [String]
}

struct TrustPrivateSignals: Hashable {
    var profileRatio: Double
    var isMember: Bool
    var isGuest: Bool
    var hasPhone: Bool
    var photoVerified: Bool = false
    var accountCreatedAt: Date?
    var friendCount: Int
    var liveHostedCount: Int
}
