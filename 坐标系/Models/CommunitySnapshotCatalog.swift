//
//  CommunitySnapshotCatalog.swift
//  坐标系
//

import CoordinateData
import CoordinateModels
import Foundation

enum CommunitySnapshotCatalog {
    static func repair(from previous: CommunitySnapshot) -> CommunitySnapshot {
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
}

struct AppCommunitySnapshotPolicy: CommunitySnapshotPersistencePolicy {
    func fallbackSnapshot() -> CommunitySnapshot { .emptySeed }

    func afterLoad(_ loaded: CommunitySnapshot) -> (snapshot: CommunitySnapshot, shouldPersist: Bool) {
        let repaired = CommunitySnapshotCatalog.repair(from: loaded)
        return (repaired, !SnapshotCodableCompare.equal(loaded, repaired))
    }
}
