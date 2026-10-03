//
//  BuddiesModel+Browse.swift
//  坐标系
//
//  搭子发现：货架列表、排序、身份查找与隐藏。
//

import CoordinateDomain
import CoordinateModels
import Foundation

extension BuddiesModel {
    /// Release：仅 Flag 开时用样例。DEBUG：Flag 开，或远程目录尚未回填时回落样例（避免联调半开空页）。
    var sampleCatalogEnabled: Bool {
        if BuddiesSupplyPolicy.allowsSampleDiscoverCatalog { return true }
        #if DEBUG
        let freeEmpty = discoverCatalog?.freeBuddies.isEmpty ?? true
        let paidEmpty = discoverCatalog?.paidCompanions.isEmpty ?? true
        return freeEmpty && paidEmpty
        #else
        false
        #endif
    }

    var allCircles: [InterestCircle] {
        let source = sampleCatalogEnabled ? catalogCircles : userClubs
        return source.filter {
            matchesBrowseLocation($0.city) && !isJoined($0)
        }
    }

    var allGuilds: [CompanionGuild] {
        guard sampleCatalogEnabled else { return [] }
        return SampleData.companionGuilds.filter { matchesBrowseLocation($0.city) }
    }

    var allVoiceHalls: [VoiceHall] {
        guard sampleCatalogEnabled else { return [] }
        return SampleData.voiceHalls.filter { matchesBrowseLocation($0.city) }
    }

    var freeItems: [DiscoverBuddyItem] {
        if sampleCatalogEnabled {
            let key = freeDiscoveryKey
            if key == freeItemsCacheKey { return freeItemsCache }
            let sorted = SampleData.circleBuddies
                .filter {
                    var base = filter
                    base.availableOnly = false
                    return !blockedUserNames.contains($0.profile.nickname)
                        && !isHidden(nickname: $0.profile.nickname)
                        && $0.profile.matches(base)
                        && matchesBrowseLocation($0.profile.city)
                }
                .map(DiscoverBuddyItem.free)
                .sorted { $0.matchScore > $1.matchScore }
            freeItemsCacheKey = key
            freeItemsCache = sorted
            return sorted
        }

        let key = freeDiscoveryKey
        if key == freeItemsCacheKey { return freeItemsCache }
        let remoteBuddies = discoverCatalog?.freeBuddies ?? []
        let sorted = remoteBuddies
            .map(BuddiesDiscoverCatalogMapping.circleBuddy(from:))
            .filter {
                var base = filter
                base.availableOnly = false
                return !blockedUserNames.contains($0.profile.nickname)
                    && !isHidden(nickname: $0.profile.nickname)
                    && $0.profile.matches(base)
                    && matchesBrowseLocation($0.profile.city)
            }
            .map(DiscoverBuddyItem.free)
            .sorted { $0.matchScore > $1.matchScore }
        freeItemsCacheKey = key
        freeItemsCache = sorted
        return sorted
    }

    var paidItems: [DiscoverBuddyItem] {
        if sampleCatalogEnabled {
            let key = paidDiscoveryKey
            if key == paidItemsCacheKey { return paidItemsCache }
            let sorted = SampleData.paidCompanions
                .filter { companion in
                    guard !blockedUserNames.contains(companion.profile.nickname),
                          !isHidden(nickname: companion.profile.nickname),
                          matchesBrowseLocation(companion.profile.city),
                          filter.serviceType == nil || companion.serviceType == filter.serviceType,
                          !filter.availableOnly || companion.isAvailable
                    else { return false }

                    var base = filter
                    let query = base.query
                    base.query = ""
                    guard companion.profile.matches(base) else { return false }

                    let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
                    if q.isEmpty { return true }
                    return companion.profile.matchesQuery(q)
                        || companion.specialty.localizedCaseInsensitiveContains(q)
                }
                .map(DiscoverBuddyItem.paid)
                .sorted { lhs, rhs in
                    switch (lhs, rhs) {
                    case (.paid(let a), .paid(let b)):
                        if a.isVerified != b.isVerified { return a.isVerified && !b.isVerified }
                        if a.isAvailable != b.isAvailable { return a.isAvailable && !b.isAvailable }
                        if lhs.matchScore != rhs.matchScore { return lhs.matchScore > rhs.matchScore }
                        return a.hourlyPrice < b.hourlyPrice
                    default:
                        return lhs.matchScore > rhs.matchScore
                    }
                }
            paidItemsCacheKey = key
            paidItemsCache = sorted
            return sorted
        }

        let key = paidDiscoveryKey
        if key == paidItemsCacheKey { return paidItemsCache }
        let remoteCompanions = discoverCatalog?.paidCompanions ?? []
        let sorted = remoteCompanions
            .map(BuddiesDiscoverCatalogMapping.paidCompanion(from:))
            .filter { companion in
                guard !blockedUserNames.contains(companion.profile.nickname),
                      !isHidden(nickname: companion.profile.nickname),
                      matchesBrowseLocation(companion.profile.city),
                      filter.serviceType == nil || companion.serviceType == filter.serviceType,
                      !filter.availableOnly || companion.isAvailable
                else { return false }

                var base = filter
                let query = base.query
                base.query = ""
                guard companion.profile.matches(base) else { return false }

                let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
                if q.isEmpty { return true }
                return companion.profile.matchesQuery(q)
                    || companion.specialty.localizedCaseInsensitiveContains(q)
            }
            .map(DiscoverBuddyItem.paid)
            .sorted { lhs, rhs in
                switch (lhs, rhs) {
                case (.paid(let a), .paid(let b)):
                    if a.isVerified != b.isVerified { return a.isVerified && !b.isVerified }
                    if a.isAvailable != b.isAvailable { return a.isAvailable && !b.isAvailable }
                    if lhs.matchScore != rhs.matchScore { return lhs.matchScore > rhs.matchScore }
                    return a.hourlyPrice < b.hourlyPrice
                default:
                    return lhs.matchScore > rhs.matchScore
                }
            }
        paidItemsCacheKey = key
        paidItemsCache = sorted
        return sorted
    }

    var stageItems: [DiscoverBuddyItem] {
        isPaidPage ? paidItems : freeItems
    }

    var isPaidPage: Bool { filter.kind == .paid }

    func sortedPeople(_ items: [DiscoverBuddyItem], by sort: BuddyPeopleSort) -> [DiscoverBuddyItem] {
        switch sort {
        case .recommended:
            let looking = filter.query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !looking.isEmpty else { return items }
            return items.sorted { lhs, rhs in
                let lm = lhs.profile.matchesQuery(looking)
                let rm = rhs.profile.matchesQuery(looking)
                if lm != rm { return lm && !rm }
                return lhs.matchScore > rhs.matchScore
            }
        case .active:
            return items.sorted { activeRank($0) > activeRank($1) }
        }
    }

    func sortedBookings(_ items: [DiscoverBuddyItem], by sort: BuddyBookingSort) -> [DiscoverBuddyItem] {
        switch sort {
        case .recommended:
            return items
        case .price:
            return items.sorted { lhs, rhs in
                guard case .paid(let a) = lhs, case .paid(let b) = rhs else {
                    return lhs.matchScore > rhs.matchScore
                }
                if a.isAvailable != b.isAvailable { return a.isAvailable && !b.isAvailable }
                if a.hourlyPrice != b.hourlyPrice { return a.hourlyPrice < b.hourlyPrice }
                return lhs.matchScore > rhs.matchScore
            }
        case .earliest:
            return items.sorted { lhs, rhs in
                guard case .paid(let a) = lhs, case .paid(let b) = rhs else {
                    return lhs.matchScore > rhs.matchScore
                }
                if a.isAvailable != b.isAvailable { return a.isAvailable && !b.isAvailable }
                let ra = earliestSlotRank(a)
                let rb = earliestSlotRank(b)
                if ra != rb { return ra < rb }
                return a.hourlyPrice < b.hourlyPrice
            }
        }
    }

    /// 标题菜单切换找搭子 / 约陪玩；深链可调用。
    func showSocialPage() {
        filter.kind = .free
    }

    /// 标题菜单切换找搭子 / 约陪玩；深链可调用。
    func showPaidPage() {
        filter.kind = .paid
    }

    func resetBrowseFilters() {
        filter.reset()
        usesSystemLocation = true
    }

    func hidePerson(nickname: String) {
        hiddenBuddyNames.insert(nickname)
        flash(BuddyFeedbackCopy.hideSimilar)
    }

    func isHidden(nickname: String) -> Bool {
        hiddenBuddyNames.contains {
            $0.caseInsensitiveCompare(nickname) == .orderedSame
        }
    }
}
