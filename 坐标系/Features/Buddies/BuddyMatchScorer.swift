//
//  BuddyMatchScorer.swift
//  坐标系
//

import Foundation

enum BuddyMatchScorer {
    /// 由 AppModel 在启动 / 引导 / 改资料后注入
    static var myInterests: [String] = SampleData.currentUserInterests

    static func sharedHobbies(with profile: BuddyProfile) -> [String] {
        profile.tags.filter { tag in
            myInterests.contains {
                tag.localizedCaseInsensitiveContains($0) || $0.localizedCaseInsensitiveContains(tag)
            }
        }
    }

    /// 共同爱好 > 可约 > 更近 > 活跃
    static func score(for profile: BuddyProfile) -> Int {
        var value = sharedHobbies(with: profile).count * MatchWeights.sharedHobby
        if !profile.availability.contains("已满") { value += MatchWeights.availableBonus }
        value += max(0, 15 - Int(profile.distanceKM))
        if profile.lastActiveText.contains("刚刚") || profile.lastActiveText.contains("在线") {
            value += MatchWeights.onlineBonus
        }
        return value
    }

    static func cardHobbyLine(for profile: BuddyProfile) -> String {
        let shared = sharedHobbies(with: profile)
        if !shared.isEmpty {
            return "共同爱好：\(shared.prefix(2).joined(separator: " · "))"
        }
        if !profile.lookingFor.isEmpty {
            return profile.lookingFor
        }
        return "爱好 · \(profile.hobbiesText)"
    }

    static func cardStatusLine(for profile: BuddyProfile, isOnline: Bool = false) -> String {
        var parts: [String] = []
        if isOnline {
            parts.append("在线")
        } else if !profile.lastActiveText.isEmpty {
            parts.append(profile.lastActiveText)
        }
        if !profile.availability.isEmpty {
            parts.append(profile.availability)
        }
        return parts.joined(separator: " · ")
    }

    static func reason(for profile: BuddyProfile) -> String {
        let shared = sharedHobbies(with: profile)
        if !shared.isEmpty {
            return "因为你们都喜欢\(shared.prefix(3).joined(separator: "、"))，且\(profile.availability)"
        }
        if !profile.lookingFor.isEmpty {
            return "\(profile.lookingFor) · \(profile.availability)"
        }
        return "\(cardHobbyLine(for: profile)) · \(profile.availability)"
    }
}

extension BuddyProfile {
    func matches(_ filter: BuddyFilter) -> Bool {
        if let gender = filter.gender, self.gender != gender { return false }
        if distanceKM > filter.maxDistanceKM { return false }
        if let hobby = filter.hobby,
           !tags.contains(where: { $0.localizedCaseInsensitiveContains(hobby) }) {
            return false
        }
        if filter.availableOnly, availability.contains("已满") { return false }
        return true
    }
}

extension SampleData {
    static func activities(named titles: [String]) -> [Activity] {
        activities.filter { titles.contains($0.title) }
    }
}
