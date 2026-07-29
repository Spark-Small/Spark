//
//  ActivityCommentsStore.swift
//  坐标系
//
//  活动详情评论区（本地持久化）。
//

import Foundation

struct ActivityComment: Identifiable, Hashable, Codable {
    let id: UUID
    var author: String
    var text: String
    var postedAt: Date

    func isOwned(by userName: String) -> Bool {
        author == userName
    }
}

@MainActor
enum ActivityCommentsStore {
    private static let fileName = "activity_comments.json"
    private static var cache: [String: [ActivityComment]] = loadAll()

    static func comments(for activityID: Activity.ID) -> [ActivityComment] {
        let key = activityID.uuidString
        if let list = cache[key] { return list }
        let seeds = seedComments(for: activityID)
        if !seeds.isEmpty {
            cache[key] = seeds
            persist()
        }
        return seeds
    }

    static func add(_ text: String, activityID: Activity.ID, author: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let word = ContentModeration.containsSensitive(trimmed) {
            return "评论包含敏感词「\(word)」"
        }
        let key = activityID.uuidString
        var list = cache[key] ?? seedComments(for: activityID)
        list.append(
            ActivityComment(id: UUID(), author: author, text: trimmed, postedAt: .now)
        )
        cache[key] = list
        persist()
        return nil
    }

    static func delete(commentID: UUID, activityID: Activity.ID, author: String) {
        let key = activityID.uuidString
        guard var list = cache[key] else { return }
        list.removeAll { $0.id == commentID && $0.author == author }
        cache[key] = list
        persist()
    }

    static func resetAll() {
        cache = [:]
        persist()
    }

    private static func seedComments(for activityID: Activity.ID) -> [ActivityComment] {
        guard let activity = SampleData.activities.first(where: { $0.id == activityID }) else {
            return []
        }
        let seeds: [(String, String, Int)] = [
            ("Mia", "想确认一下集合地点具体在哪边？", -180),
            ("阿凯", "还有名额吗？我可以带一位朋友吗？", -120),
            ("小周", "上次参加过\(activity.hostName)的局，组织很靠谱。", -60)
        ]
        let count = 1 + abs(activity.id.stableSeed % 3)
        return seeds.prefix(count).map { author, text, minutes in
            ActivityComment(
                id: UUID(),
                author: author,
                text: text,
                postedAt: Date().addingTimeInterval(TimeInterval(minutes * 60))
            )
        }
    }

    private static func loadAll() -> [String: [ActivityComment]] {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [ActivityComment]].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func persist() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
