//
//  DiscoverBuddyItem.swift
//  坐标系
//

import Foundation

enum DiscoverBuddyItem: Identifiable, Hashable {
    case free(CircleBuddy)
    case paid(PaidCompanion)

    var id: UUID {
        switch self {
        case .free(let buddy): buddy.id
        case .paid(let companion): companion.id
        }
    }

    var profile: BuddyProfile {
        switch self {
        case .free(let buddy): buddy.profile
        case .paid(let companion): companion.profile
        }
    }

    var inviteEnabled: Bool {
        switch self {
        case .free: true
        case .paid(let companion): companion.isAvailable
        }
    }

    var isOnline: Bool {
        switch self {
        case .free(let buddy): buddy.isOnline
        case .paid: false
        }
    }

    /// 卡面主 meta：同好看爱好重合；陪玩看擅长
    var cardHobbyLine: String {
        switch self {
        case .free:
            return BuddyMatchScorer.cardHobbyLine(for: profile)
        case .paid(let companion):
            return companion.specialty
        }
    }

    /// 卡面状态行：同好看活跃；陪玩看档期/响应
    var cardStatusLine: String {
        switch self {
        case .free(let buddy):
            return BuddyMatchScorer.cardStatusLine(for: buddy.profile, isOnline: buddy.isOnline)
        case .paid(let companion):
            var parts: [String] = []
            if companion.isAvailable {
                parts.append(BuddyDetailCopy.available)
            }
            if !companion.profile.availability.isEmpty {
                parts.append(companion.profile.availability)
            } else if !companion.responseTime.isEmpty {
                parts.append(companion.responseTime)
            }
            return parts.joined(separator: " · ")
        }
    }

    /// 卡面一句状态：优先 lookingFor，否则回退状态行
    var cardMoodLine: String {
        let looking = profile.lookingFor.trimmingCharacters(in: .whitespacesAndNewlines)
        if !looking.isEmpty { return looking }
        return cardStatusLine
    }

    var matchScore: Int {
        BuddyMatchScorer.score(for: profile)
    }
}
