// Module: SparkCommunity — Community tab state.

import Foundation
import Observation
import SparkCore

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
    public private(set) var discoverPeople: [DiscoveredPerson] = []
    public private(set) var allCommunities: [CommunitySummary] = []
    public private(set) var loadState: LoadState = .idle
    public private(set) var likedPostIDs: Set<String> = []
    public private(set) var likedPersonIDs: Set<String> = []
    public private(set) var likeCountOverrides: [String: Int] = [:]

    public var discoverableCommunities: [CommunitySummary] {
        CommunityFeedRelevance.discoverableCommunities(
            all: allCommunities,
            joined: joinedCommunities
        )
    }

    /// Home feed posts after Plan A relevance filtering (no people-discovery rows).
    public var homeFeedPosts: [CommunityFeedPost] {
        feedItems.compactMap { item in
            guard case .post(let post) = item else { return nil }
            return post
        }
    }

    private let fetchPosts: any FetchCommunityPostsUseCaseProtocol
    private let fetchTabExperience: any FetchCommunityTabExperienceUseCaseProtocol
    private let createRecap: any CreateCommunityRecapUseCaseProtocol
    private let createPost: any CreateCommunityPostUseCaseProtocol

    public init(
        fetchPosts: any FetchCommunityPostsUseCaseProtocol,
        fetchTabExperience: any FetchCommunityTabExperienceUseCaseProtocol,
        createRecap: any CreateCommunityRecapUseCaseProtocol,
        createPost: any CreateCommunityPostUseCaseProtocol
    ) {
        self.fetchPosts = fetchPosts
        self.fetchTabExperience = fetchTabExperience
        self.createRecap = createRecap
        self.createPost = createPost
    }

    public convenience init(repository: any CommunityPostsRepository) {
        self.init(
            fetchPosts: FetchCommunityPostsUseCase(repository: repository),
            fetchTabExperience: FetchCommunityTabExperienceUseCase(repository: repository),
            createRecap: CreateCommunityRecapUseCase(repository: repository),
            createPost: CreateCommunityPostUseCase(repository: repository)
        )
    }

    public func load() async {
        loadState = .loading
        do {
            async let postsTask = fetchPosts()
            async let tabTask = fetchTabExperience()
            let (fetchedPosts, tab) = try await (postsTask, tabTask)
            posts = fetchedPosts
            joinedCommunities = tab.joinedCommunities
            allCommunities = tab.allCommunities
            discoverPeople = CommunityFeedRelevance.discoverPeople(from: tab.feedItems)
            feedItems = CommunityFeedRelevance.homeFeedItems(
                from: tab.feedItems,
                joinedCommunities: tab.joinedCommunities
            )
            let discoverable = CommunityFeedRelevance.discoverableCommunities(
                all: tab.allCommunities,
                joined: tab.joinedCommunities
            )
            let hasHomeContent = !feedItems.isEmpty || !tab.joinedCommunities.isEmpty
            loadState = hasHomeContent || !discoverable.isEmpty ? .loaded : .empty
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

    @discardableResult
    public func publishRecap(_ draft: CommunityRecapDraft) async throws -> CommunityPostDetail {
        let detail = try await createRecap(draft)
        let summary = MockCommunityPostCatalog.summary(from: detail)
        posts.insert(summary, at: 0)
        insertFeedPost(
            from: summary,
            linkedActivity: detail.linkedActivity,
            shareMedia: draft.publishedMedia
        )
        IntegrationTelemetry.activityEndToRecap(activityID: draft.activityID)
        return detail
    }

    public func insertPublishedPost(_ result: PublishedCommunityPostResult) {
        posts.insert(result.post, at: 0)
        insertFeedPost(from: result.post, linkedActivity: nil, shareMedia: result.mediaItems)
    }

    private func insertFeedPost(
        from post: CommunityPost,
        linkedActivity: LinkedActivityContext?,
        shareMedia: [SparkGalleryMedia] = []
    ) {
        let feedPost = CommunityFeedPost(
            id: post.id,
            authorDisplayName: post.authorDisplayName,
            authorUserID: "viewer",
            communityName: joinedCommunities.first?.name
                ?? String(
                    localized: "community.compose.feed.communityName",
                    defaultValue: "Spark 社区",
                    comment: "Default community name"
                ),
            content: post.excerpt,
            imageURL: shareMedia.first?.url,
            mediaItems: shareMedia,
            likeCount: 0,
            commentCount: post.replyCount,
            createdAt: Date(),
            linkedActivity: linkedActivity
                ?? post.linkedActivityID.flatMap { activityID in
                    guard let title = post.linkedActivityTitle else { return nil }
                    return LinkedActivityContext(id: activityID, name: title)
                },
            kind: post.kind
        )
        feedItems.insert(.post(feedPost), at: 0)
        if loadState == .empty {
            loadState = .loaded
        }
    }
}
