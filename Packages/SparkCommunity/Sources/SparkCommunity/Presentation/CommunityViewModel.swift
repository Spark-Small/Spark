// Module: SparkCommunity — Community tab state.

import Foundation
import Observation

@MainActor
@Observable
public final class CommunityViewModel {
    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case empty
        case failure(String)
    }

    public private(set) var posts: [CommunityPost] = []
    public private(set) var joinedCommunities: [CommunitySummary] = []
    public private(set) var feedItems: [CommunityFeedItem] = []
    public private(set) var allCommunities: [CommunitySummary] = []
    public private(set) var loadState: LoadState = .idle
    public private(set) var likedPostIDs: Set<String> = []
    public private(set) var likedPersonIDs: Set<String> = []
    public private(set) var likeCountOverrides: [String: Int] = [:]

    private let fetchPosts: FetchCommunityPostsUseCase
    private let repository: any CommunityPostsRepository

    public init(repository: any CommunityPostsRepository) {
        self.repository = repository
        fetchPosts = FetchCommunityPostsUseCase(repository: repository)
    }

    public func load() async {
        loadState = .loading
        do {
            async let postsTask = fetchPosts()
            async let tabTask = repository.fetchTabExperience()
            let (fetchedPosts, tab) = try await (postsTask, tabTask)
            posts = fetchedPosts
            joinedCommunities = tab.joinedCommunities
            feedItems = tab.feedItems
            allCommunities = tab.allCommunities
            loadState = feedItems.isEmpty && posts.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }

    public func toggleLike(postID: String) {
        let currentlyLiked = likedPostIDs.contains(postID)
        if currentlyLiked {
            likedPostIDs.remove(postID)
        } else {
            likedPostIDs.insert(postID)
        }
        let base = likeCount(for: postID)
        likeCountOverrides[postID] = base + (currentlyLiked ? -1 : 1)
    }

    public func markPersonLiked(_ userID: String) {
        likedPersonIDs.insert(userID)
    }

    public func isPostLiked(_ postID: String) -> Bool {
        likedPostIDs.contains(postID)
    }

    public func likeCount(for postID: String) -> Int {
        if let override = likeCountOverrides[postID] {
            return max(0, override)
        }
        for item in feedItems {
            if case .post(let post) = item, post.id == postID {
                return post.likeCount
            }
        }
        return 0
    }
}
