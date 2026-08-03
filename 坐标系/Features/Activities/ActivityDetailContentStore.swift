//
//  ActivityDetailContentStore.swift
//  坐标系
//
//  活动详情分区内容的本地覆盖：模板作默认，发起人可写实覆盖。
//

import Foundation

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
                CommunityPhotoStore.delete(named: name)
            }
        }
        cache.removeValue(forKey: key)
        persist()
    }

    static func resetAll() {
        for override in cache.values {
            for name in override.galleryPhotoNames ?? [] {
                CommunityPhotoStore.delete(named: name)
            }
        }
        cache = [:]
        persist()
    }

    /// 详情页相册：封面 + 额外配图
    static func galleryPhotos(for activity: Activity) -> [CommunityPhotoRef] {
        var refs: [CommunityPhotoRef] = []
        if let cover = activity.coverPhoto {
            refs.append(cover)
        }
        let extras = override(for: activity.id)?.galleryPhotoNames ?? []
        for name in extras where name != activity.localCoverName {
            if let url = CommunityPhotoStore.fileURL(named: name) {
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

/// 发起人摘要：本地场次 + 目录画像 + 演示徽章（人对人星级已下线）
struct ActivityHostTrust: Hashable {
    let name: String
    let hostedCount: Int
    let completionRate: Int
    /// 认证徽章
    let isVerified: Bool
    /// 会员徽章
    let isMember: Bool
    /// 等级 1…5（演示档位，与行为信用 TrustLevel 分账）
    let level: Int

    var hostedText: String { "举办\u{00A0}\(hostedCount)\u{00A0}场" }
    var completionText: String { "履约\u{00A0}\(completionRate)%" }
    var levelText: String { "Lv.\(level)" }
    /// 第二行整行文案（避免 HStack 在窄宽下把「场」拆到下一行）
    var metricsLine: String {
        "\(hostedText) · \(completionText)"
    }

    static func make(hostName: String, liveHostedCount: Int) -> ActivityHostTrust {
        let profile = SampleData.author(named: hostName)
        let hosted = max(liveHostedCount, profile.hostedCount, 1)
        let seed = abs(hostName.stableSeed)
        let rate = 86 + seed % 13
        let isOfficial = profile.roleLabel.contains("官方")
        let isVerified = isOfficial || hosted >= 8 || seed % 3 == 0
        let isMember = isOfficial || profile.roleLabel.contains("活跃") || seed % 2 == 0
        let level = min(5, max(1, hosted / 3 + 1))
        return ActivityHostTrust(
            name: hostName,
            hostedCount: hosted,
            completionRate: rate,
            isVerified: isVerified,
            isMember: isMember,
            level: level
        )
    }
}
