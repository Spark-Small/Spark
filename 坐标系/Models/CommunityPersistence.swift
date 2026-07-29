//
//  CommunityPersistence.swift
//  坐标系
//

import Foundation

/// 社区本地快照：帖子 + 互动状态（可商用冷启动 / 杀进程可恢复）
struct CommunitySnapshot: Codable {
    var posts: [CommunityPost]
    var likedIDs: [UUID]
    var repostedIDs: [UUID]
    var bookmarkedIDs: [UUID]
    var bookmarkCollections: [String: String]
    var reportedIDs: [UUID]
    var likedCommentIDs: [UUID]

    static let emptySeed = CommunitySnapshot(
        posts: SampleData.posts,
        likedIDs: [],
        repostedIDs: [],
        bookmarkedIDs: [],
        bookmarkCollections: [:],
        reportedIDs: [],
        likedCommentIDs: []
    )

    init(
        posts: [CommunityPost],
        likedIDs: [UUID],
        repostedIDs: [UUID],
        bookmarkedIDs: [UUID],
        bookmarkCollections: [String: String],
        reportedIDs: [UUID],
        likedCommentIDs: [UUID] = []
    ) {
        self.posts = posts
        self.likedIDs = likedIDs
        self.repostedIDs = repostedIDs
        self.bookmarkedIDs = bookmarkedIDs
        self.bookmarkCollections = bookmarkCollections
        self.reportedIDs = reportedIDs
        self.likedCommentIDs = likedCommentIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        posts = try container.decode([CommunityPost].self, forKey: .posts)
        likedIDs = try container.decode([UUID].self, forKey: .likedIDs)
        repostedIDs = try container.decode([UUID].self, forKey: .repostedIDs)
        bookmarkedIDs = try container.decode([UUID].self, forKey: .bookmarkedIDs)
        bookmarkCollections = try container.decode([String: String].self, forKey: .bookmarkCollections)
        reportedIDs = try container.decode([UUID].self, forKey: .reportedIDs)
        likedCommentIDs = try container.decodeIfPresent([UUID].self, forKey: .likedCommentIDs) ?? []
    }
}

enum CommunityPersistence {
    private static let fileName = "community_snapshot.json"

    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent(fileName)
    }

    static func load() -> CommunitySnapshot {
        guard let data = try? Data(contentsOf: fileURL),
              let snapshot = try? JSONDecoder().decode(CommunitySnapshot.self, from: data)
        else {
            let seed = CommunitySnapshot.emptySeed
            save(seed)
            return seed
        }
        let repaired = repairedSnapshot(from: snapshot)
        if !codableContentsEqual(snapshot, repaired) {
            save(repaired)
        }
        return repaired
    }

    static func save(_ snapshot: CommunitySnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func resetToSeed() {
        save(.emptySeed)
    }

    static func repairedSnapshot(from previous: CommunitySnapshot) -> CommunitySnapshot {
        guard !previous.posts.isEmpty else { return .emptySeed }

        let repairedPosts = previous.posts.map(repairedPost)
        let validPostIDs = Set(repairedPosts.map(\.id))
        let validCommentIDs = Set(repairedPosts.flatMap(\.comments).map(\.id))

        return CommunitySnapshot(
            posts: repairedPosts,
            likedIDs: previous.likedIDs.filter(validPostIDs.contains),
            repostedIDs: previous.repostedIDs.filter(validPostIDs.contains),
            bookmarkedIDs: previous.bookmarkedIDs.filter(validPostIDs.contains),
            bookmarkCollections: Dictionary(
                uniqueKeysWithValues: previous.bookmarkCollections.compactMap { key, value in
                    guard let id = UUID(uuidString: key),
                          validPostIDs.contains(id)
                    else { return nil }
                    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : (key, trimmed)
                }
            ),
            reportedIDs: previous.reportedIDs.filter(validPostIDs.contains),
            likedCommentIDs: previous.likedCommentIDs.filter(validCommentIDs.contains)
        )
    }

    private static func repairedPost(_ post: CommunityPost) -> CommunityPost {
        var repaired = post
        let commentIDs = Set(post.comments.map(\.id))

        repaired.comments = post.comments.map { comment in
            var fixed = comment
            if let parentID = fixed.parentID, !commentIDs.contains(parentID) {
                fixed.parentID = nil
                fixed.replyToAuthor = nil
            }
            return fixed
        }
        repaired.commentCount = repaired.comments.count

        var seenLikers = Set<String>()
        repaired.likerNames = post.likerNames.filter { seenLikers.insert($0).inserted }
        repaired.likeCount = max(post.likeCount, repaired.likerNames.count)

        if let repostedFromID = repaired.repostedFromID,
           !post.id.uuidString.isEmpty,
           repostedFromID == post.id {
            repaired.repostedFromID = nil
        }

        repaired.reportCount = max(post.reportCount, 0)
        return repaired
    }

    private static func codableContentsEqual<T: Codable>(_ lhs: T, _ rhs: T) -> Bool {
        guard let lhsData = try? JSONEncoder().encode(lhs),
              let rhsData = try? JSONEncoder().encode(rhs)
        else { return false }
        return lhsData == rhsData
    }
}
