//
//  BuddiesModel+Browse.swift
//  坐标系
//
//  搭子发现：定位、货架列表、排序与隐藏。
//

import CoordinateModels
import Foundation

extension BuddiesModel {
    var selectedCity: BuddyCityChoice {
        BuddyCityCatalog.city(id: selectedCityID) ?? BuddyCityCatalog.default
    }

    /// Release 发现页不以 SampleData 为人设主路径。
    private var sampleCatalogEnabled: Bool { BuddiesSupplyPolicy.allowsSampleDiscoverCatalog }

    var hasActiveBrowseFilters: Bool {
        !filter.isDefault || !usesSystemLocation
    }

    var browseRegionAccessibilityLabel: String {
        if usesSystemLocation {
            if let locatedPlaceName, !locatedPlaceName.isEmpty {
                return "当前定位 \(locatedPlaceName)"
            }
            return "正在定位"
        }
        return selectedCity.menuTitle
    }

    func matchesBrowseLocation(_ locationText: String) -> Bool {
        if usesSystemLocation {
            if let locatedPlaceName, !locatedPlaceName.isEmpty {
                if let resolved = BuddyCityCatalog.all.first(where: {
                    $0.matches(locationText: locatedPlaceName)
                }) {
                    return resolved.matches(locationText: locationText)
                }
                return locationText.localizedCaseInsensitiveContains(locatedPlaceName)
            }
            return BuddyCityCatalog.default.matches(locationText: locationText)
        }
        return selectedCity.matches(locationText: locationText)
    }

    func syncLocatedPlaceName(_ placeName: String?) {
        locatedPlaceName = placeName
        if usesSystemLocation,
           let placeName,
           let match = BuddyCityCatalog.all.first(where: { $0.matches(locationText: placeName) }) {
            selectedCityID = match.id
        }
    }

    func useSystemLocationMode() {
        usesSystemLocation = true
    }

    func selectManualCity(id: String) {
        usesSystemLocation = false
        selectedCityID = id
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
        guard sampleCatalogEnabled else {
            freeItemsCacheKey = freeDiscoveryKey
            freeItemsCache = []
            return []
        }
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

    var paidItems: [DiscoverBuddyItem] {
        guard sampleCatalogEnabled else {
            paidItemsCacheKey = paidDiscoveryKey
            paidItemsCache = []
            return []
        }
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

    func showSocialPage() {
        filter.kind = .free
    }

    /// 同页展示同好与陪玩；保留供深链 / Tab 跳转，不再切换整页内容。
    func showPaidPage() {
        filter.kind = .paid
    }

    func item(for nickname: String) -> DiscoverBuddyItem? {
        if let hit = freeItems.first(where: {
            $0.profile.nickname.caseInsensitiveCompare(nickname) == .orderedSame
        }) ?? paidItems.first(where: {
            $0.profile.nickname.caseInsensitiveCompare(nickname) == .orderedSame
        }) {
            return hit
        }
        guard sampleCatalogEnabled else { return nil }
        return SampleData.circleBuddies
            .first { $0.profile.nickname.caseInsensitiveCompare(nickname) == .orderedSame }
            .map(DiscoverBuddyItem.free)
            ?? SampleData.paidCompanions
                .first { $0.profile.nickname.caseInsensitiveCompare(nickname) == .orderedSame }
                .map(DiscoverBuddyItem.paid)
    }

    func discoverItem(
        for nickname: String,
        fallbackCircleName: String,
        fallbackTopic: String = ""
    ) -> DiscoverBuddyItem {
        if let item = item(for: nickname) {
            return item
        }
        let author = SampleData.author(named: nickname)
        return .free(
            CircleBuddy(
                profile: BuddyProfile(
                    id: UUID(),
                    nickname: author.name,
                    gender: .male,
                    age: 26,
                    heightCM: 170,
                    weightKG: 62,
                    distanceKM: 1.2,
                    photoSeeds: [abs(author.name.hashValue) % 9000 + 100],
                    city: author.city,
                    bio: author.bio,
                    tags: author.tags,
                    availability: BuddyDetailCopy.available,
                    lastActiveText: "今天活跃",
                    lookingFor: "同城约局"
                ),
                circleName: fallbackCircleName,
                topic: fallbackTopic,
                isOnline: false,
                scheduleSlots: [],
                relatedActivityTitles: []
            )
        )
    }

    func resetBrowseFilters() {
        filter.reset()
        usesSystemLocation = true
    }

    func hidePerson(nickname: String) {
        hiddenBuddyNames.insert(nickname)
        flash("已减少类似推荐")
    }

    func isHidden(nickname: String) -> Bool {
        hiddenBuddyNames.contains {
            $0.caseInsensitiveCompare(nickname) == .orderedSame
        }
    }

    func companions(in guild: CompanionGuild) -> [PaidCompanion] {
        guard sampleCatalogEnabled else { return [] }
        let metro = guild.city
            .split(separator: "·")
            .first
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            ?? guild.city
        let specialtyKey = guild.specialty
            .replacingOccurrences(of: "陪玩", with: "")
            .trimmingCharacters(in: .whitespaces)

        let inMetro = SampleData.paidCompanions.filter {
            $0.profile.city.localizedCaseInsensitiveContains(metro)
                && !isHidden(nickname: $0.profile.nickname)
                && !blockedUserNames.contains($0.profile.nickname)
        }

        let matched = inMetro.filter { companion in
            companion.specialty.localizedCaseInsensitiveContains(specialtyKey)
                || guild.tags.contains { tag in
                    companion.profile.tags.contains { $0.localizedCaseInsensitiveContains(tag) }
                        || companion.specialty.localizedCaseInsensitiveContains(tag)
                }
        }

        let list = matched.isEmpty ? inMetro : matched
        return list.sorted { lhs, rhs in
            if lhs.isVerified != rhs.isVerified { return lhs.isVerified && !rhs.isVerified }
            return lhs.orderCount > rhs.orderCount
        }
    }

    var freeDiscoveryKey: String {
        "free|\(usesSystemLocation)|\(locatedPlaceName ?? "")|\(selectedCityID)|\(filter.gender?.rawValue ?? "")|\(filter.maxDistanceKM)|\(filter.hobby ?? "")|\(filter.query)|\(blockedUserNames.sorted().joined(separator: ","))|\(hiddenBuddyNames.sorted().joined(separator: ","))"
    }

    var paidDiscoveryKey: String {
        "paid|\(usesSystemLocation)|\(locatedPlaceName ?? "")|\(selectedCityID)|\(filter.gender?.rawValue ?? "")|\(filter.maxDistanceKM)|\(filter.hobby ?? "")|\(filter.query)|\(filter.serviceType?.rawValue ?? "")|\(filter.availableOnly)|\(blockedUserNames.sorted().joined(separator: ","))|\(hiddenBuddyNames.sorted().joined(separator: ","))"
    }

    func activeRank(_ item: DiscoverBuddyItem) -> Int {
        if case .free(let buddy) = item, buddy.isOnline { return 300 }
        let text = item.profile.lastActiveText
        if text.contains("刚刚") || text.contains(BuddyDetailCopy.online) { return 200 }
        if text.contains("分钟") { return 150 }
        if text.contains("小时") || text.contains("今天") { return 100 }
        if text.contains("昨天") { return 50 }
        return 0
    }

    func earliestSlotRank(_ companion: PaidCompanion) -> Int {
        if !companion.isAvailable { return 10_000 }
        let text = (
            companion.scheduleSlots.first
                ?? companion.profile.availability
        ).lowercased()
        if text.isEmpty { return 800 }
        if text.contains("今晚") || text.contains("今天") { return 0 }
        if text.contains("小时") || text.contains("分钟") { return 20 }
        if text.contains("明天") { return 40 }
        if text.contains("周末") { return 120 }
        return 200
    }
}
