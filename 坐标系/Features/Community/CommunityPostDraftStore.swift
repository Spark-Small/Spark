//
//  CommunityPostDraftStore.swift
//  坐标系
//
//  社区发帖草稿：本机多草稿列表（UserDefaults），不进 CommunitySnapshot / 远程合并。
//

import Foundation
import UIKit

struct CommunityPostDraft: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var body: String
    var tags: [String]
    var localPhotoNames: [String]
    var relatedActivityID: UUID?
    var relatedActivityTitle: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        body: String = "",
        tags: [String] = [],
        localPhotoNames: [String] = [],
        relatedActivityID: UUID? = nil,
        relatedActivityTitle: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.body = body
        self.tags = tags
        self.localPhotoNames = localPhotoNames
        self.relatedActivityID = relatedActivityID
        self.relatedActivityTitle = relatedActivityTitle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var hasContent: Bool {
        !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !localPhotoNames.isEmpty
            || !tags.isEmpty
            || relatedActivityID != nil
            || !(relatedActivityTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var previewText: String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        if !localPhotoNames.isEmpty {
            return "含 \(localPhotoNames.count) 项媒体"
        }
        if let title = relatedActivityTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
           !title.isEmpty {
            return title
        }
        if !tags.isEmpty {
            return tags.map { "#\($0)" }.joined(separator: " ")
        }
        return "空白草稿"
    }
}

enum CommunityPostDraftStore {
    private static let keyPrefix = "compose.communityPostDrafts."

    private static func key(for userID: UUID) -> String {
        keyPrefix + userID.uuidString
    }

    static func loadAll(userID: UUID = LocalUserIdentity.current) -> [CommunityPostDraft] {
        guard let data = UserDefaults.standard.data(forKey: key(for: userID)),
              let drafts = try? JSONDecoder().decode([CommunityPostDraft].self, from: data)
        else { return [] }
        return drafts.sorted { $0.updatedAt > $1.updatedAt }
    }

    static func draft(id: UUID, userID: UUID = LocalUserIdentity.current) -> CommunityPostDraft? {
        loadAll(userID: userID).first { $0.id == id }
    }

    /// 写入或更新；会删除本次不再引用的旧媒体文件。
    static func upsert(_ draft: CommunityPostDraft, userID: UUID = LocalUserIdentity.current) {
        var drafts = loadAll(userID: userID)
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            let previousNames = Set(drafts[index].localPhotoNames)
            let nextNames = Set(draft.localPhotoNames)
            for name in previousNames where !nextNames.contains(name) {
                LocalMediaLibrary.delete(named: name)
            }
            drafts[index] = draft
        } else {
            drafts.insert(draft, at: 0)
        }
        persist(drafts, userID: userID)
    }

    static func delete(id: UUID, deleteMedia: Bool = true, userID: UUID = LocalUserIdentity.current) {
        var drafts = loadAll(userID: userID)
        guard let index = drafts.firstIndex(where: { $0.id == id }) else { return }
        if deleteMedia {
            for name in drafts[index].localPhotoNames {
                LocalMediaLibrary.delete(named: name)
            }
        }
        drafts.remove(at: index)
        persist(drafts, userID: userID)
    }

    static func clear(userID: UUID = LocalUserIdentity.current) {
        for draft in loadAll(userID: userID) {
            for name in draft.localPhotoNames {
                LocalMediaLibrary.delete(named: name)
            }
        }
        UserDefaults.standard.removeObject(forKey: key(for: userID))
    }

    private static func persist(_ drafts: [CommunityPostDraft], userID: UUID) {
        guard let data = try? JSONEncoder().encode(drafts) else { return }
        UserDefaults.standard.set(data, forKey: key(for: userID))
    }
}

enum CommunityPostDraftMedia {
    @MainActor
    static func previewImages(for names: [String]) async -> [UIImage] {
        var images: [UIImage] = []
        images.reserveCapacity(names.count)
        for name in names {
            guard let url = LocalMediaLibrary.fileURL(named: name) else { continue }
            if LocalMediaLibrary.isVideo(url: url) {
                if let poster = await LocalMediaLibrary.posterImage(for: url) {
                    images.append(poster)
                }
            } else if let image = await PlatformLocalImageCache.loadAsync(atPath: url.path) {
                images.append(image)
            }
        }
        return images
    }
}
