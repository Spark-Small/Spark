//
//  BuddiesModel+BrowseLookup.swift
//  坐标系
//
//  搭子发现：身份查找、公会成员与排序权重。
//

import CoordinateDomain
import CoordinateModels
import Foundation

extension BuddiesModel {
    func item(for nickname: String, userID: UUID? = nil) -> DiscoverBuddyItem? {
        if let hit = freeItems.first(where: {
            matchesIdentity(
                nickname: $0.profile.nickname,
                userID: $0.profile.userID,
                otherNickname: nickname,
                otherUserID: userID
            )
        }) ?? paidItems.first(where: {
            matchesIdentity(
                nickname: $0.profile.nickname,
                userID: $0.profile.userID,
                otherNickname: nickname,
                otherUserID: userID
            )
        }) {
            return hit
        }
        guard sampleCatalogEnabled else {
            if let catalog = discoverCatalog {
                if let dto = catalog.freeBuddies.first(where: {
                    ParticipantIdentity.matches(
                        nickname: $0.nickname,
                        userID: $0.userID,
                        otherNickname: nickname,
                        otherUserID: userID
                    )
                }) {
                    return .free(BuddiesDiscoverCatalogMapping.circleBuddy(from: dto))
                }
                if let dto = catalog.paidCompanions.first(where: {
                    ParticipantIdentity.matches(
                        nickname: $0.nickname,
                        userID: $0.userID,
                        otherNickname: nickname,
                        otherUserID: userID
                    )
                }) {
                    return .paid(BuddiesDiscoverCatalogMapping.paidCompanion(from: dto))
                }
            }
            return nil
        }
        return SampleData.circleBuddies
            .first {
                ParticipantIdentity.matches(
                    nickname: $0.profile.nickname,
                    userID: $0.profile.userID,
                    otherNickname: nickname,
                    otherUserID: userID
                )
            }
            .map(DiscoverBuddyItem.free)
            ?? SampleData.paidCompanions
                .first {
                    ParticipantIdentity.matches(
                        nickname: $0.profile.nickname,
                        userID: $0.profile.userID,
                        otherNickname: nickname,
                        otherUserID: userID
                    )
                }
                .map(DiscoverBuddyItem.paid)
    }

    /// 最近浏览：按档案 / 陪玩 id 回查发现项。
    func discoverItem(id: UUID) -> DiscoverBuddyItem? {
        if let hit = freeItems.first(where: { $0.id == id }) ?? paidItems.first(where: { $0.id == id }) {
            return hit
        }
        if sampleCatalogEnabled {
            if let buddy = SampleData.circleBuddies.first(where: { $0.id == id }) {
                return .free(buddy)
            }
            if let companion = SampleData.paidCompanions.first(where: { $0.id == id }) {
                return .paid(companion)
            }
        }
        if let catalog = discoverCatalog {
            if let dto = catalog.freeBuddies.first(where: { $0.id == id }) {
                return .free(BuddiesDiscoverCatalogMapping.circleBuddy(from: dto))
            }
            if let dto = catalog.paidCompanions.first(where: { $0.id == id }) {
                return .paid(BuddiesDiscoverCatalogMapping.paidCompanion(from: dto))
            }
        }
        return nil
    }

    func discoverItem(
        for nickname: String,
        fallbackCircleName: String,
        fallbackTopic: String = "",
        userID: UUID? = nil
    ) -> DiscoverBuddyItem {
        if let item = item(for: nickname, userID: userID) {
            return item
        }
        let displayName = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedUserID = userID
            ?? (displayName.isEmpty ? nil : ParticipantIdentity.stableUserID(forNickname: displayName))
        let profile: BuddyProfile
        if BuddiesSupplyPolicy.allowsSampleDiscoverCatalog {
            let author = SampleData.author(named: displayName)
            profile = BuddyProfile(
                id: resolvedUserID ?? UUID(),
                userID: resolvedUserID,
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
                lastActiveText: BuddyBrowseCopy.ModelCopy.seedLastActive,
                lookingFor: BuddyBrowseCopy.ModelCopy.seedLookingFor
            )
        } else {
            profile = BuddyProfile(
                id: resolvedUserID ?? UUID(),
                userID: resolvedUserID,
                nickname: displayName.isEmpty ? BuddyBrowseCopy.ModelCopy.memberFallback : displayName,
                gender: .male,
                age: 0,
                heightCM: 0,
                weightKG: 0,
                distanceKM: 0,
                photoSeeds: [abs(displayName.hashValue) % 9000 + 100],
                city: "",
                bio: "",
                tags: [],
                availability: BuddyDetailCopy.available,
                lastActiveText: "",
                lookingFor: ""
            )
        }
        return .free(
            CircleBuddy(
                profile: profile,
                circleName: fallbackCircleName,
                topic: fallbackTopic,
                isOnline: false,
                scheduleSlots: [],
                relatedActivityTitles: []
            )
        )
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
        "free|\(sampleCatalogEnabled)|\(usesSystemLocation)|\(locatedPlaceName ?? "")|\(selectedCityID)|\(filter.gender?.rawValue ?? "")|\(filter.maxDistanceKM)|\(filter.hobby ?? "")|\(filter.intents.map(\.rawValue).sorted().joined(separator: ","))|\(filter.query)|\(blockedUserNames.sorted().joined(separator: ","))|\(hiddenBuddyNames.sorted().joined(separator: ","))|\(discoverCatalogFingerprint)"
    }

    var paidDiscoveryKey: String {
        "paid|\(sampleCatalogEnabled)|\(usesSystemLocation)|\(locatedPlaceName ?? "")|\(selectedCityID)|\(filter.gender?.rawValue ?? "")|\(filter.maxDistanceKM)|\(filter.hobby ?? "")|\(filter.query)|\(filter.serviceType?.rawValue ?? "")|\(filter.availableOnly)|\(blockedUserNames.sorted().joined(separator: ","))|\(hiddenBuddyNames.sorted().joined(separator: ","))|\(discoverCatalogFingerprint)"
    }

    private var discoverCatalogFingerprint: String {
        guard let catalog = discoverCatalog else { return "none" }
        return "c\(catalog.freeBuddies.count):\(catalog.paidCompanions.count):\(catalog.freeBuddies.first?.id.uuidString ?? "-"):\(catalog.paidCompanions.first?.id.uuidString ?? "-")"
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
