//
//  CommunityModel+Moderation.swift
//  坐标系
//

import Foundation
import Observation
import CoordinateModels

extension CommunityModel {
    func syncComments(for postID: CommunityPost.ID) {
        CommunityCommentsStore.syncCommentCount(for: postID, in: &posts)
        bumpComments()
        persist()
    }

    func deletePost(_ id: CommunityPost.ID) -> Bool {
        guard let index = posts.firstIndex(where: { $0.id == id }),
              isOwnPost(posts[index]) else { return false }
        for name in posts[index].localPhotoNames {
            LocalMediaLibrary.delete(named: name)
        }
        CommunityCommentsStore.removeAll(for: id)
        likedIDs.remove(id)
        repostedIDs.remove(id)
        bookmarkedIDs.remove(id)
        bookmarkCollections[id] = nil
        reportedIDs.remove(id)
        posts.remove(at: index)
        persist()
        return true
    }

    func reportPost(_ id: CommunityPost.ID, reason: String) -> Bool {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return false }
        posts[index].reportCount += 1
        reportedIDs.insert(id)
        persist()
        return true
    }
}
