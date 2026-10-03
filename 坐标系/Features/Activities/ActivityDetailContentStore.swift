//
//  ActivityDetailContentStore.swift
//  坐标系
//
//  活动详情分区内容的本地覆盖：模板作默认，发起人可写实覆盖。
//

import Foundation
import CoordinateModels

struct ActivityDetailContentOverride: Codable, Hashable {
    /// 自定义行程（为空则用类别模板）
    var timeline: [PersistedTimelineItem]?
    var gear: [PersistedGearItem]?
    /// 详情相册（不含封面 localCoverName）
    var galleryPhotoNames: [String]?
    var feeIncluded: [String]?
    var feeExcluded: [String]?
    var refundNotes: [String]?
    var prepNotes: [String]?
    var registrationNotes: [String]?
    /// 发起人补充说明（展示在决策卡下方）
    var hostNote: String?

    struct PersistedTimelineItem: Codable, Hashable {
        var time: String
        var title: String
        var detail: String
    }

    struct PersistedGearItem: Codable, Hashable {
        var title: String
        var detail: String
        var systemImage: String
    }
}

@MainActor
enum ActivityDetailContentStore {
    private static let fileName = "activity_detail_overrides.json"

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    private static var cache: [String: ActivityDetailContentOverride] = loadAll()

    static func override(for id: Activity.ID) -> ActivityDetailContentOverride? {
        cache[id.uuidString]
    }

    static func save(_ override: ActivityDetailContentOverride, for id: Activity.ID) {
        var cleaned = override
        if cleaned.timeline?.isEmpty == true { cleaned.timeline = nil }
        if cleaned.gear?.isEmpty == true { cleaned.gear = nil }
        if cleaned.galleryPhotoNames?.isEmpty == true { cleaned.galleryPhotoNames = nil }
        if cleaned.feeIncluded?.isEmpty == true { cleaned.feeIncluded = nil }
        if cleaned.feeExcluded?.isEmpty == true { cleaned.feeExcluded = nil }
        if cleaned.refundNotes?.isEmpty == true { cleaned.refundNotes = nil }
        if cleaned.prepNotes?.isEmpty == true { cleaned.prepNotes = nil }
        if cleaned.registrationNotes?.isEmpty == true { cleaned.registrationNotes = nil }
        if cleaned.hostNote?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            cleaned.hostNote = nil
        }

        let key = id.uuidString
        let isEmpty = cleaned.timeline == nil
            && cleaned.gear == nil
            && cleaned.galleryPhotoNames == nil
            && cleaned.feeIncluded == nil
            && cleaned.feeExcluded == nil
            && cleaned.refundNotes == nil
            && cleaned.prepNotes == nil
            && cleaned.registrationNotes == nil
            && cleaned.hostNote == nil

        if isEmpty {
            cache.removeValue(forKey: key)
        } else {
            cache[key] = cleaned
        }
        persist()
    }

    static func delete(for id: Activity.ID) {
        let key = id.uuidString
        if let names = cache[key]?.galleryPhotoNames {
            for name in names {
                LocalMediaLibrary.delete(named: name)
            }
        }
        cache.removeValue(forKey: key)
        persist()
    }

    static func resetAll() {
        for override in cache.values {
            for name in override.galleryPhotoNames ?? [] {
                LocalMediaLibrary.delete(named: name)
            }
        }
        cache = [:]
        persist()
    }

    /// 详情页相册：封面 + 额外配图。
    /// - Parameter galleryExtraNames: 非 nil 时覆盖本地 store（发起预览用）。
    static func galleryPhotos(
        for activity: Activity,
        galleryExtraNames: [String]? = nil
    ) -> [CommunityPhotoRef] {
        var refs: [CommunityPhotoRef] = []
        if let cover = activity.coverPhoto {
            refs.append(cover)
        }
        let extras = galleryExtraNames ?? override(for: activity.id)?.galleryPhotoNames ?? []
        for name in extras where name != activity.localCoverName {
            if let url = LocalMediaLibrary.fileURL(named: name) {
                refs.append(.file(url))
            }
        }
        return refs
    }

    private static func loadAll() -> [String: ActivityDetailContentOverride] {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: ActivityDetailContentOverride].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func persist() {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: fileURL, options: [.atomic])
    }
}

/// 发起人摘要：以可核验的举办场次为主；认证仅官方身份，不做种子演示徽章。
struct ActivityHostTrust: Hashable {
    let name: String
    let hostedCount: Int
    /// 认证徽章（官方账号）
    let isVerified: Bool
    /// 活跃身份徽章（角色标签）
    let isMember: Bool

    var hostedText: String { "举办\u{00A0}\(hostedCount)\u{00A0}场" }
    /// 第二行整行文案（避免 HStack 在窄宽下把「场」拆到下一行）
    var metricsLine: String { hostedText }

    static func make(hostName: String, liveHostedCount: Int) -> ActivityHostTrust {
        let profile = SampleData.author(named: hostName)
        let hosted = max(liveHostedCount, profile.hostedCount)
        let isOfficial = profile.roleLabel.contains("官方")
        let isActiveHost = profile.roleLabel.contains("活跃") || profile.roleLabel.contains("发起")
        return ActivityHostTrust(
            name: hostName,
            hostedCount: hosted,
            isVerified: isOfficial,
            isMember: isOfficial || isActiveHost
        )
    }
}
