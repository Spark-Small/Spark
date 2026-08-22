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

    /// 列表「为什么推给你」：搜索意图契合 · 共同兴趣 · 距离 · 活跃
    static func browseReason(
        for profile: BuddyProfile,
        isOnline: Bool = false,
        intentQuery: String = ""
    ) -> String {
        var parts: [String] = []
        let intent = intentQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !intent.isEmpty, profile.matchesQuery(intent) {
            parts.append("契合搜索")
        }
        let shared = sharedHobbies(with: profile)
        if !shared.isEmpty {
            parts.append("共同 \(shared.prefix(2).joined(separator: "·"))")
        } else if !profile.tags.isEmpty {
            parts.append(profile.tags.prefix(2).joined(separator: "·"))
        }
        if PrivacyPreferences.showDistance {
            parts.append(profile.distanceText)
        }
        if isOnline, PrivacyPreferences.showOnline {
            parts.append("在线")
        } else if !profile.lastActiveText.isEmpty {
            parts.append(profile.lastActiveText)
        }
        return parts.joined(separator: " · ")
    }

    /// 是否与当前搜索意图重合（卡面角标）
    static func matchesIntent(_ profile: BuddyProfile, query: String) -> Bool {
        let intent = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !intent.isEmpty else { return false }
        return profile.matchesQuery(intent)
    }

    /// 打招呼带上对方意图或共同兴趣，避免空话
    static func greetMessage(for profile: BuddyProfile) -> String {
        let looking = profile.lookingFor.trimmingCharacters(in: .whitespacesAndNewlines)
        if !looking.isEmpty {
            return "你好，看到你想「\(looking)」，我也想一起，方便聊聊吗？"
        }
        let shared = sharedHobbies(with: profile)
        if !shared.isEmpty {
            let hobbies = shared.prefix(2).joined(separator: "、")
            return "你好，看到我们都喜欢\(hobbies)，想一起玩吗？"
        }
        return "你好，想一起玩吗？"
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
        let q = filter.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty, !matchesQuery(q) { return false }
        if filter.availableOnly, availability.contains("已满") { return false }
        return true
    }

    func matchesQuery(_ query: String) -> Bool {
        let haystacks = [nickname, lookingFor, bio, hobbiesText, availability] + tags
        return haystacks.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    func matchesKeywords(_ keywords: [String]) -> Bool {
        let haystacks = [lookingFor, bio, hobbiesText, availability] + tags
        return keywords.contains { key in
            haystacks.contains { $0.localizedCaseInsensitiveContains(key) }
        }
    }
}

extension SampleData {
    static func activities(named titles: [String]) -> [Activity] {
        activities.filter { titles.contains($0.title) }
    }
}
