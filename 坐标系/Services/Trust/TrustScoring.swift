//
//  TrustScoring.swift
//  坐标系
//
//  行为事件 → 四轴与等级（近 90 天为主）。
//

import Foundation

enum TrustScoring {
    static let windowDays = 90
    static let decayAlpha = 0.85

    static func windowStart(from now: Date = .now) -> Date {
        Calendar.current.date(byAdding: .day, value: -windowDays, to: now) ?? now
    }

    static func facts(
        for key: String,
        events: [TrustBehaviorEvent],
        signals: TrustPrivateSignals,
        now: Date = .now
    ) -> TrustBehaviorFacts {
        let since = windowStart(from: now)
        let recent = events.filter { $0.createdAt >= since }

        let joined = recent.filter { $0.name == .activityJoined }.count
        let left = recent.filter { $0.name == .activityLeft }.count
        let joinedKept = max(0, joined - left)

        let hosted = recent.filter { $0.name == .activityHosted }.count
        let hostCancel = recent.filter { $0.name == .activityHostCancelled }.count

        let bookingDone = recent.filter { $0.name == .bookingCompleted }.count
        let bookingBad = recent.filter {
            $0.name == .bookingCancelled || $0.name == .bookingRefunded
        }.count

        let age: Int = {
            if let created = signals.accountCreatedAt {
                return max(0, Calendar.current.dateComponents([.day], from: created, to: now).day ?? 0)
            }
            return 0
        }()

        return TrustBehaviorFacts(
            accountAgeDays: age,
            joinedKept: joinedKept,
            joinedTotal: max(joined, joinedKept),
            hostedCompletedLike: max(0, hosted - hostCancel) + max(0, signals.liveHostedCount - hostCancel),
            hostedCancelled: hostCancel,
            bookingsCompleted: bookingDone,
            bookingsCancelledOrRefunded: bookingBad,
            eventCount90d: recent.count
        )
    }

    static func axes(
        for key: String,
        events: [TrustBehaviorEvent],
        signals: TrustPrivateSignals,
        facts: TrustBehaviorFacts,
        now: Date = .now
    ) -> TrustAxisScores {
        let since = windowStart(from: now)
        let recent = events.filter { $0.createdAt >= since }

        // Identity
        var identity = 35.0
        if !signals.isGuest { identity += 20 }
        if signals.hasPhone { identity += 15 }
        identity += min(20, signals.profileRatio * 20)
        if signals.isMember { identity += 10 }
        if signals.photoVerified { identity += 12 }

        // Reliability
        var reliability = 55.0
        if facts.joinedTotal > 0 {
            let rate = Double(facts.joinedKept) / Double(facts.joinedTotal)
            reliability = 40 + rate * 45
        }
        reliability += min(12, Double(facts.bookingsCompleted) * 3)
        reliability -= min(25, Double(facts.bookingsCancelledOrRefunded) * 8)
        reliability -= min(30, Double(facts.hostedCancelled) * 12)
        let checkOK = recent.filter { $0.name == .safetyCheckinOK }.count
        let checkBad = recent.filter { $0.name == .safetyCheckinIssue }.count
        reliability += min(8, Double(checkOK) * 2)
        reliability -= min(20, Double(checkBad) * 10)

        // Communication
        var communication = 50.0
        let accepts = recent.filter { $0.name == .inviteAccepted }.count
        let declines = recent.filter { $0.name == .inviteDeclined }.count
        let invites = recent.filter { $0.name == .inviteSent }.count
        communication += min(20, Double(accepts) * 4)
        communication -= min(15, Double(declines) * 3)
        if invites > 8, accepts == 0 {
            communication -= 12
        }
        communication += min(10, Double(signals.friendCount) * 0.5)

        // Safety
        var safety = 80.0
        let blocksAgainst = events.filter {
            $0.name == .blocked && ($0.subjectKey?.caseInsensitiveCompare(key) == .orderedSame)
        }.count
        let reportsAgainst = events.filter {
            ($0.name == .personReported || $0.name == .ticketResolvedAgainst)
                && ($0.subjectKey?.caseInsensitiveCompare(key) == .orderedSame)
        }.count
        safety -= min(50, Double(blocksAgainst) * 8 + Double(reportsAgainst) * 15)
        safety -= min(15, Double(checkBad) * 5)

        return TrustAxisScores(
            identity: clamp(identity),
            reliability: clamp(reliability),
            communication: clamp(communication),
            safety: clamp(safety)
        )
    }

    static func level(
        axes: TrustAxisScores,
        signals: TrustPrivateSignals,
        facts: TrustBehaviorFacts
    ) -> TrustLevel {
        if signals.isGuest { return .guest }
        if axes.safety < 45 { return .restricted }
        let score = axes.overall
        if facts.hostedCompletedLike >= 3, facts.hostedCancelled == 0, score >= 70 {
            return .reliableHost
        }
        if score >= 68, facts.eventCount90d >= 3 {
            return .trusted
        }
        return .newcomer
    }

    static func badges(
        level: TrustLevel,
        verification: TrustVerification,
        signals: TrustPrivateSignals,
        facts: TrustBehaviorFacts
    ) -> [TrustBadge] {
        var list = verification.badges
        if signals.isMember { list.append(TrustBadge(kind: .activeMember)) }
        if level == .reliableHost || (facts.hostedCompletedLike >= 3 && facts.hostedCancelled == 0) {
            list.append(TrustBadge(kind: .reliableHost))
        }
        if level == .trusted || level == .reliableHost {
            list.append(TrustBadge(kind: .trustedNeighbor))
        }
        var seen = Set<TrustBadgeKind>()
        return list.filter { seen.insert($0.kind).inserted }
    }

    static func growthTips(axes: TrustAxisScores, signals: TrustPrivateSignals, facts: TrustBehaviorFacts) -> [String] {
        var tips: [String] = []
        if signals.isGuest {
            tips.append("创建账号并验证手机，身份强度会明显提升。")
        } else if !signals.photoVerified {
            tips.append("完成形象认证（自拍与头像比对），可降低冒用风险并点亮徽章。")
        } else if signals.profileRatio < 0.7 {
            tips.append("完善头像、兴趣与简介，有助于匹配与信任展示。")
        }
        if facts.joinedTotal < 2 {
            tips.append("参加 2 场活动并正常履约，守约分会更稳。")
        }
        if facts.bookingsCancelledOrRefunded > facts.bookingsCompleted {
            tips.append("减少临期取消与退款，有助于守约表现。")
        }
        if axes.communication < 60 {
            tips.append("及时回应邀约与消息请求，沟通会更可信。")
        }
        if tips.isEmpty {
            tips.append("保持履约与友善互动即可；信用会随近 90 天行为缓慢更新。")
        }
        return Array(tips.prefix(3))
    }

    static func safetyTips(isGuest: Bool, phoneVerified: Bool) -> [String] {
        var tips = [
            "首次见面选公共场所，并告知好友行程。",
            "不要在站外提前转账；退款走应用内流程。",
            "遇到骚扰请举报或拉黑，工单在设置可查。"
        ]
        if isGuest {
            tips.insert("创建账号后可点亮认证徽章，并解锁交易能力。", at: 0)
        } else if !phoneVerified {
            tips.insert("绑定手机号可点亮「手机已验证」。", at: 0)
        }
        return tips
    }

    private static func clamp(_ value: Double) -> Double {
        min(100, max(0, (value * 10).rounded() / 10))
    }
}
