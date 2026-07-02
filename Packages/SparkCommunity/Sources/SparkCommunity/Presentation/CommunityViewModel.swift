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
    public private(set) var allCommunities: [CommunitySummary] = []
    public private(set) var loadState: LoadState = .idle
    public private(set) var likedPersonIDs: Set<String> = []
    public private(set) var pendingLikePostIDs: Set<String> = []

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
    private let setPostLike: any SetCommunityPostLikeUseCaseProtocol

    public init(
        fetchPosts: any FetchCommunityPostsUseCaseProtocol,
        fetchTabExperience: any FetchCommunityTabExperienceUseCaseProtocol,
        createRecap: any CreateCommunityRecapUseCaseProtocol,
        createPost: any CreateCommunityPostUseCaseProtocol,
        setPostLike: any SetCommunityPostLikeUseCaseProtocol
    ) {
        self.fetchPosts = fetchPosts
        self.fetchTabExperience = fetchTabExperience
        self.createRecap = createRecap
        self.createPost = createPost
        self.setPostLike = setPostLike
    }

    public convenience init(repository: any CommunityPostsRepository) {
        self.init(
            fetchPosts: FetchCommunityPostsUseCase(repository: repository),
            fetchTabExperience: FetchCommunityTabExperienceUseCase(repository: repository),
            createRecap: CreateCommunityRecapUseCase(repository: repository),
            createPost: CreateCommunityPostUseCase(repository: repository),
            setPostLike: SetCommunityPostLikeUseCase(repository: repository)
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

    public func toggleLike(postID: String) async {
        guard let current = feedPost(id: postID), !pendingLikePostIDs.contains(postID) else { return }
        let targetLiked = !current.viewerHasLiked
        pendingLikePostIDs.insert(postID)
        let rollback = CommunityPostLikeResult(
            viewerHasLiked: current.viewerHasLiked,
            likeCount: current.likeCount
        )
        applyLikeResult(
            CommunityPostLikeResult(
                viewerHasLiked: targetLiked,
                likeCount: max(0, current.likeCount + (targetLiked ? 1 : -1))
            ),
            postID: postID
        )
        do {
            let result = try await setPostLike(postID: postID, liked: targetLiked)
            applyLikeResult(result, postID: postID)
            if targetLiked {
                IntegrationTelemetry.communityPostLiked(
                    postID: postID,
                    hasLinkedActivity: current.linkedActivity != nil
                )
            }
        } catch is CancellationError {
            applyLikeResult(rollback, postID: postID)
        } catch {
            applyLikeResult(rollback, postID: postID)
        }
        pendingLikePostIDs.remove(postID)
    }

    public func markPersonLiked(_ userID: String) {
        likedPersonIDs.insert(userID)
    }

    public func isPostLiked(_ postID: String) -> Bool {
        feedPost(id: postID)?.viewerHasLiked ?? false
    }

    public func isLikePending(_ postID: String) -> Bool {
        pendingLikePostIDs.contains(postID)
    }

    public func likeCount(for postID: String) -> Int {
        feedPost(id: postID)?.likeCount ?? 0
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

    private func feedPost(id: String) -> CommunityFeedPost? {
        for item in feedItems {
            if case .post(let post) = item, post.id == id {
                return post
            }
        }
        return nil
    }

    private func applyLikeResult(_ result: CommunityPostLikeResult, postID: String) {
        feedItems = feedItems.map { item in
            guard case .post(let post) = item, post.id == postID else { return item }
            return .post(
                CommunityFeedPost(
                    id: post.id,
                    authorDisplayName: post.authorDisplayName,
                    authorUserID: post.authorUserID,
                    authorAvatarURL: post.authorAvatarURL,
                    communityName: post.communityName,
                    content: post.content,
                    imageURL: post.imageURL,
                    mediaItems: post.mediaItems,
                    likeCount: result.likeCount,
                    commentCount: post.commentCount,
                    tags: post.tags,
                    createdAt: post.createdAt,
                    sharedActivityWithViewer: post.sharedActivityWithViewer,
                    relationshipToViewer: post.relationshipToViewer,
                    linkedActivity: post.linkedActivity,
                    kind: post.kind,
                    viewerHasLiked: result.viewerHasLiked
                )
            )
        }
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
            kind: post.kind,
            viewerHasLiked: false
        )
        feedItems.insert(.post(feedPost), at: 0)
        if loadState == .empty {
            loadState = .loaded
        }
    }
}
