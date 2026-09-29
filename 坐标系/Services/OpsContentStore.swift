//
//  OpsContentStore.swift
//  坐标系
//
//  运营公告 + 用户反馈（本机演示账本）。
//

import Foundation
import Observation
import CoordinateModels

struct OpsAnnouncement: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let body: String
    let publishedAt: Date
    let pin: Bool
}

struct OpsFeedbackRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let category: String
    let content: String
    let contact: String
    let createdAt: Date
    var status: String
}

@MainActor
@Observable
final class OpsContentStore {
    static var shared: OpsContentStore { AppComposition.opsContentStore }

    private static let feedbackFile = "ops_feedback.json"
    private static let dismissedAnnouncementsKey = "ops.dismissedAnnouncements"

    private(set) var feedback: [OpsFeedbackRecord]
    private(set) var dismissedAnnouncementIDs: Set<String>

    /// 内置运营公告（随版本更新文案即可）
    let announcements: [OpsAnnouncement] = [
        OpsAnnouncement(
            id: "2026-q3-trust",
            title: "我的信誉上线",
            body: "行为信用上线：近 90 天履约事实与认证徽章对外展示；人对人星级评价已下线。",
            publishedAt: Date(timeIntervalSince1970: 1_751_328_000),
            pin: true
        ),
        OpsAnnouncement(
            id: "2026-q3-orders",
            title: "统一订单入口",
            body: "活动支付与陪玩预约合并到「我的订单」，退款与凭证仍走对应详情。",
            publishedAt: Date(timeIntervalSince1970: 1_751_241_600),
            pin: false
        ),
        OpsAnnouncement(
            id: "demo-local",
            title: "当前为本地演示环境",
            body: "支付、登录与举报均在本机模拟；正式版将接入合规支付与云端风控。",
            publishedAt: Date(timeIntervalSince1970: 1_750_291_200),
            pin: false
        )
    ]

    init() {
        feedback = Self.loadFeedback()
        let dismissed = UserDefaults.standard.stringArray(forKey: Self.dismissedAnnouncementsKey) ?? []
        dismissedAnnouncementIDs = Set(dismissed)
    }

    var visibleAnnouncements: [OpsAnnouncement] {
        announcements
            .filter { !dismissedAnnouncementIDs.contains($0.id) }
            .sorted {
                if $0.pin != $1.pin { return $0.pin && !$1.pin }
                return $0.publishedAt > $1.publishedAt
            }
    }

    var unreadAnnouncementCount: Int {
        visibleAnnouncements.count
    }

    func dismissAnnouncement(_ id: String) {
        dismissedAnnouncementIDs.insert(id)
        UserDefaults.standard.set(Array(dismissedAnnouncementIDs), forKey: Self.dismissedAnnouncementsKey)
    }

    @discardableResult
    func submitFeedback(category: String, content: String, contact: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 4 else { return false }
        let entry = OpsFeedbackRecord(
            id: UUID(),
            category: category,
            content: trimmed,
            contact: contact.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: .now,
            status: "已收到"
        )
        feedback.insert(entry, at: 0)
        persistFeedback()
        return true
    }

    func resetAll() {
        feedback = []
        dismissedAnnouncementIDs = []
        persistFeedback()
        UserDefaults.standard.removeObject(forKey: Self.dismissedAnnouncementsKey)
    }

    private static func loadFeedback() -> [OpsFeedbackRecord] {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(feedbackFile)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([OpsFeedbackRecord].self, from: data)
        else { return [] }
        return decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private func persistFeedback() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Self.feedbackFile)
        guard let data = try? JSONEncoder().encode(feedback) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
