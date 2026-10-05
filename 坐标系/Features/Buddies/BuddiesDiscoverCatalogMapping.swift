//
//  BuddiesDiscoverCatalogMapping.swift
//  坐标系
//
//  远程发现目录 DTO → 本地 UI 模型（契约已备；B4 真人供给仍待后端）。
//

import Foundation
import CoordinateModels

enum BuddiesDiscoverCatalogMapping {
    static func circleBuddy(from dto: BuddiesDiscoverBuddyDTO) -> CircleBuddy {
        CircleBuddy(
            profile: profile(from: dto),
            circleName: dto.circleName,
            topic: dto.topic,
            isOnline: dto.isOnline,
            scheduleSlots: dto.scheduleSlots,
            relatedActivityTitles: dto.relatedActivityTitles
        )
    }

    static func paidCompanion(from dto: BuddiesDiscoverCompanionDTO) -> PaidCompanion {
        PaidCompanion(
            profile: profile(from: dto),
            serviceType: serviceType(from: dto.serviceType),
            specialty: dto.specialty,
            hourlyPrice: dto.hourlyPrice,
            pricingUnit: pricingUnit(from: dto.pricingUnit),
            orderCount: dto.orderCount,
            isAvailable: dto.isAvailable,
            responseTime: dto.responseTime,
            scheduleSlots: dto.scheduleSlots,
            relatedActivityTitles: dto.relatedActivityTitles,
            isVerified: dto.isVerified
        )
    }

    private static func profile(from dto: BuddiesDiscoverBuddyDTO) -> BuddyProfile {
        let remoteGallery = galleryURLs(dto.galleryImageURLs)
        return BuddyProfile(
            id: dto.id,
            userID: dto.userID,
            nickname: dto.nickname,
            gender: gender(from: dto.gender),
            age: dto.age,
            heightCM: 0,
            weightKG: 0,
            distanceKM: dto.distanceKM,
            photoSeeds: remoteGallery.isEmpty ? seedGallery(for: dto.id) : [],
            city: dto.city,
            bio: dto.bio,
            tags: dto.tags,
            availability: dto.availability,
            lastActiveText: dto.lastActiveText,
            lookingFor: dto.lookingFor,
            intents: profileIntents(dto.intents, legacyLookingFor: dto.lookingFor),
            galleryRemoteURLs: remoteGallery
        )
    }

    private static func profile(from dto: BuddiesDiscoverCompanionDTO) -> BuddyProfile {
        let remoteGallery = galleryURLs(dto.galleryImageURLs)
        return BuddyProfile(
            id: dto.id,
            userID: dto.userID,
            nickname: dto.nickname,
            gender: gender(from: dto.gender),
            age: dto.age,
            heightCM: 0,
            weightKG: 0,
            distanceKM: dto.distanceKM,
            photoSeeds: remoteGallery.isEmpty ? seedGallery(for: dto.id) : [],
            city: dto.city,
            bio: dto.bio,
            tags: dto.tags,
            availability: dto.availability,
            lastActiveText: dto.lastActiveText,
            lookingFor: dto.lookingFor,
            intents: profileIntents(dto.intents, legacyLookingFor: dto.lookingFor),
            galleryRemoteURLs: remoteGallery
        )
    }

    private static func galleryURLs(_ raw: [String]?) -> [URL] {
        (raw ?? []).compactMap { value in
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let url = URL(string: trimmed),
                  let scheme = url.scheme?.lowercased(),
                  scheme == "https" || scheme == "http"
            else { return nil }
            return url
        }
    }

    private static func profileIntents(_ raw: [String]?, legacyLookingFor: String) -> [ProfileIntent] {
        let parsed = (raw ?? []).compactMap { ProfileIntent(rawValue: $0) }
        if !parsed.isEmpty {
            return ProfileIntentLimits.clamped(parsed)
        }
        // 兼容仅下发 lookingFor 字符串：按 rawValue 子串识别
        return ProfileIntent.allCases.filter { legacyLookingFor.contains($0.rawValue) }
            .prefix(ProfileIntentLimits.maxSelected)
            .map { $0 }
    }

    /// 远程 DTO 暂无多图字段时，用稳定种子铺 3 张，发现卡可分页。
    private static func seedGallery(for id: UUID) -> [Int] {
        let base = abs(id.hashValue % 9000) + 100
        return [base, base + 1, base + 2]
    }

    private static func gender(from raw: String) -> BuddyGender {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch value {
        case "女", "female", "f":
            return .female
        default:
            return .male
        }
    }

    private static func serviceType(from raw: String) -> CompanionServiceType {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let exact = CompanionServiceType.allCases.first(where: {
            $0.rawValue == raw || $0.rawValue.lowercased() == value
        }) {
            return exact
        }
        switch value {
        case "voice", "语音", "语音陪聊":
            return .voice
        case "sport", "运动", "运动陪练":
            return .sport
        case "offline", "线下", "线下见面":
            return .offline
        case "photo", "拍照", "拍照跟拍":
            return .photo
        default:
            return .voice
        }
    }

    private static func pricingUnit(from raw: String) -> CompanionPricingUnit {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let exact = CompanionPricingUnit.allCases.first(where: {
            $0.rawValue == raw || $0.rawValue.lowercased() == value
        }) {
            return exact
        }
        switch value {
        case "halfhour", "half_hour", "30分钟", "30m":
            return .halfHour
        case "session", "次":
            return .session
        case "day", "天":
            return .day
        default:
            return .hour
        }
    }
}
