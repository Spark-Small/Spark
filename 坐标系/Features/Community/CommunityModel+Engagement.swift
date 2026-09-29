//
//  CommunityModel+Engagement.swift
//  坐标系
//

import Foundation
import Observation
import CoordinateModels

extension CommunityModel {
    func toggleLike(_ id: CommunityPost.ID) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        if likedIDs.contains(id) {
            likedIDs.remove(id)
            posts[index].likeCount = max(posts[index].likeCount - 1, 0)
            posts[index].likerNames.removeAll { $0 == currentUserName }
        } else {
            likedIDs.insert(id)
            posts[index].likeCount += 1
            if !posts[index].likerNames.contains(currentUserName) {
                posts[index].likerNames.insert(currentUserName, at: 0)
            }
        }
        persist()
    }

    func toggleRepost(_ id: CommunityPost.ID) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        if repostedIDs.contains(id) {
            repostedIDs.remove(id)
            posts[index].repostCount = max(posts[index].repostCount - 1, 0)
            posts.removeAll { $0.repostedFromID == id && $0.author == currentUserName }
            persist()
        } else {
            createRepost(of: id, quote: nil)
        }
    }

    func saveBookmark(_ id: CommunityPost.ID, collection: String) {
        bookmarkedIDs.insert(id)
        bookmarkCollections[id] = collection
        persist()
    }

    func removeBookmark(_ id: CommunityPost.ID) {
        bookmarkedIDs.remove(id)
        bookmarkCollections[id] = nil
        persist()
    }

    func recordShare(_ id: CommunityPost.ID) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        posts[index].shareCount += 1
        persist()
    }
}
