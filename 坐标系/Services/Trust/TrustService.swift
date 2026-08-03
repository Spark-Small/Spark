//
//  TrustService.swift
//  坐标系
//
//  行为信用门面：record / 对外事实卡 / 私域状态（Docs/TrustBehaviorModel.md）。
//

import Foundation
import Observation

@MainActor
@Observable
final class TrustService {
    static let shared = TrustService()

    private let ledger = TrustBehaviorLedger.shared
    private(set) var revision: Int = 0

    private init() {}

    // MARK: - Record

    func record(
        _ name: TrustEventName,
        domain: TrustDomain,
        actorKey: String,
        subjectKey: String? = nil,
        value: Double = 1,
        note: String? = nil
    ) {
        let event = TrustBehaviorEvent(
            actorKey: actorKey,
            subjectKey: subjectKey,
            domain: domain,
            name: name,
            value: value,
            note: note
        )
        ledger.append(event)
        revision += 1
    }

    // MARK: - Public card

    func publicCard(
        for nickname: String,
        currentUserName: String,
        buddyItem: DiscoverBuddyItem?,
        signals: TrustPrivateSignals
    ) -> TrustPublicCard {
        let key = nickname
        let events = ledger.events(for: key)
        let facts = TrustScoring.facts(for: key, events: events, signals: signals)
        let axes = TrustScoring.axes(for: key, events: events, signals: signals, facts: facts)
        let level = TrustScoring.level(axes: axes, signals: signals, facts: facts)
        let verification = verificationState(
            nickname: nickname,
            currentUserName: currentUserName,
            buddyItem: buddyItem,
            signals: signals
        )
        let badges = TrustScoring.badges(
            level: level,
            verification: verification,
            signals: signals,
            facts: facts
        )

        let responseHint = Self.responseHint(
            buddyItem: buddyItem,
            communication: axes.communication,
            eventCount90d: facts.eventCount90d
        )

        return TrustPublicCard(
            nickname: nickname,
            level: level,
            badges: badges,
            facts: facts,
            factLines: facts.publicFactLines,
            responseHint: responseHint,
            confidenceLow: facts.eventCount90d < 2 && level == .newcomer
        )
    }

    // MARK: - Private status

    func privateStatus(
        userName: String,
        signals: TrustPrivateSignals
    ) -> TrustPrivateStatus {
        let events = ledger.events(for: userName)
        let facts = TrustScoring.facts(for: userName, events: events, signals: signals)
        let axes = TrustScoring.axes(for: userName, events: events, signals: signals, facts: facts)
        let level = TrustScoring.level(axes: axes, signals: signals, facts: facts)
        let verification = TrustVerification(
            photoVerified: signals.photoVerified,
            phoneVerified: signals.hasPhone,
            identityVerified: false
        )
        let badges = TrustScoring.badges(
            level: level,
            verification: verification,
            signals: signals,
            facts: facts
        )
        let growthTips = TrustScoring.growthTips(axes: axes, signals: signals, facts: facts)
        let safetyTips = TrustScoring.safetyTips(
            isGuest: signals.isGuest,
            phoneVerified: verification.phoneVerified
        )
        let score = Int(axes.overall.rounded())
        return TrustPrivateStatus(
            score: score,
            level: level,
            axes: axes,
            badges: badges,
            facts: facts,
            growthTips: growthTips,
            safetyTips: safetyTips
        )
    }

    // MARK: - Safety check-in (replaces person star review)

    func submitSafetyCheckIn(
        actorKey: String,
        companionNickname: String,
        bookingID: UUID?,
        wentWell: Bool
    ) {
        let note = bookingID.map(\.uuidString)
        let name: TrustEventName = wentWell ? .safetyCheckinOK : .safetyCheckinIssue
        record(
            name,
            domain: .booking,
            actorKey: actorKey,
            subjectKey: companionNickname,
            note: note
        )
    }

    func hasCheckedIn(bookingID: UUID) -> Bool {
        let token = bookingID.uuidString
        let recorded = ledger.allEvents
        return recorded.contains { event in
            guard event.note == token else { return false }
            return event.name == .safetyCheckinOK || event.name == .safetyCheckinIssue
        }
    }

    func resetAll() {
        ledger.resetAll()
        revision += 1
    }

    /// 形象认证等旁路状态变更时刷新依赖 `revision` 的界面。
    func bumpRevision() {
        revision += 1
    }

    // MARK: - Helpers

    private static func responseHint(
        buddyItem: DiscoverBuddyItem?,
        communication: Double,
        eventCount90d: Int
    ) -> String? {
        if case .paid(let companion) = buddyItem {
            return companion.responseTime
        }
        if communication >= 70 { return "通常较快回复" }
        if eventCount90d == 0 { return nil }
        return "视活跃情况而定"
    }

    private func verificationState(
        nickname: String,
        currentUserName: String,
        buddyItem: DiscoverBuddyItem?,
        signals: TrustPrivateSignals
    ) -> TrustVerification {
        if nickname.caseInsensitiveCompare(currentUserName) == .orderedSame {
            return TrustVerification(
                photoVerified: signals.photoVerified,
                phoneVerified: signals.hasPhone,
                identityVerified: false
            )
        }
        switch buddyItem {
        case .paid(let companion):
            return TrustVerification(
                photoVerified: companion.isVerified,
                phoneVerified: companion.isVerified,
                identityVerified: companion.isVerified && companion.orderCount > 40
            )
        case .free:
            let seed = abs(nickname.stableSeed)
            return TrustVerification(
                photoVerified: seed % 3 == 0,
                phoneVerified: seed % 2 == 0,
                identityVerified: false
            )
        case .none:
            let host = ActivityHostTrust.make(hostName: nickname, liveHostedCount: 1)
            return TrustVerification(
                photoVerified: host.isVerified,
                phoneVerified: host.isMember,
                identityVerified: false
            )
        }
    }
}
