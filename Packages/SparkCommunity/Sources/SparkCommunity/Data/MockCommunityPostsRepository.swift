// Module: SparkCommunity — Mock community feed.

import Foundation

public actor MockCommunityPostsRepository: CommunityPostsRepository {
    private var replyStore: [String: [CommunityPostReply]]
    private var userCreatedPosts: [CommunityPostDetail] = []
    private var joinedCommunityIDs: Set<String>
    private var catalogLikeCounts: [String: Int] = [:]
    private var viewerLikedPostIDs: Set<String> = []

    private let currentUserID = "viewer"

    public init() {
        replyStore = MockCommunityPostCatalog.defaultReplies()
        joinedCommunityIDs = Set(MockCommunityTabCatalog.joinedCommunities().map(\.id))
    }

    public init(replyStore: [String: [CommunityPostReply]]) {
        self.replyStore = replyStore
        joinedCommunityIDs = Set(MockCommunityTabCatalog.joinedCommunities().map(\.id))
    }

    public func resetUserCreatedPosts() {
        userCreatedPosts = []
    }

    public func fetchPosts() async throws -> [CommunityPost] {
        allPostDetails().map(MockCommunityPostCatalog.summary)
    }

    private func allPostDetails() -> [CommunityPostDetail] {
        userCreatedPosts + MockCommunityPostCatalog.allPosts(replyStore: replyStore)
    }

    public func fetchTabExperience() async throws -> CommunityTabExperience {
        let experience = MockCommunityTabCatalog.tabExperience(joinedIDs: joinedCommunityIDs)
        return applyLikeState(to: experience)
    }

    public func fetchCommunityDetail(id: String) async throws -> CommunityDetail {
        guard let detail = MockCommunityDetailCatalog.detail(id: id, joinedIDs: joinedCommunityIDs) else {
            throw CommunityError.underlying(.server(statusCode: 404, message: nil))
        }
        return detail
    }

    public func joinCommunity(id: String) async throws -> CommunityDetail {
        guard MockCommunityTabCatalog.allCommunities().contains(where: { $0.id == id }) else {
            throw CommunityError.underlying(.server(statusCode: 404, message: nil))
        }
        joinedCommunityIDs.insert(id)
        guard let detail = MockCommunityDetailCatalog.detail(id: id, joinedIDs: joinedCommunityIDs) else {
            throw CommunityError.underlying(.server(statusCode: 404, message: nil))
        }
        return detail
    }

    public func fetchCommunityActivities(communityID: String) async throws -> [CommunityLinkedActivity] {
        MockCommunityDetailCatalog.activities(communityID: communityID)
    }

    public func fetchCommunityMembers(communityID: String) async throws -> [CommunityMember] {
        MockCommunityDetailCatalog.members(communityID: communityID)
    }

    public func fetchCommunityPosts(communityID: String) async throws -> [CommunityFeedPost] {
        MockCommunityDetailCatalog.posts(communityID: communityID)
    }

    public func fetchPost(id: String) async throws -> CommunityPostDetail {
        if let post = allPostDetails().first(where: { $0.id == id }) {
            return applyLikeState(to: post)
        }
        if let feedPost = MockCommunityTabCatalog.feedPosts().first(where: { $0.id == id }) {
            let replies = replyStore[id, default: []]
            let likedPost = applyLikeState(to: feedPost)
            var detail = MockCommunityTabCatalog.postDetail(for: likedPost, replies: replies)
            detail = CommunityPostDetail(
                id: detail.id,
                title: detail.title,
                body: detail.body,
                authorDisplayName: detail.authorDisplayName,
                authorUserID: detail.authorUserID,
                replyCount: detail.replyCount,
                replies: detail.replies,
                linkedActivity: detail.linkedActivity,
                mediaItems: detail.mediaItems,
                tags: detail.tags,
                kind: detail.kind,
                likeCount: likedPost.likeCount,
                viewerHasLiked: likedPost.viewerHasLiked
            )
            return detail
        }
        throw CommunityError.underlying(.server(statusCode: 404, message: nil))
    }

    public func createPost(_ draft: CreateCommunityPostDraft) async throws -> CommunityPost {
        var body = draft.body
        if !draft.mediaItems.isEmpty {
            let note = String(
                localized: "community.compose.mediaAttached",
                defaultValue: "[媒体]",
                comment: "Media attached marker"
            )
            body = body.isEmpty ? note : "\(body)\n\n\(note)"
        }
        let detail = CommunityPostDetail(
            id: "cp_mock_new_\(userCreatedPosts.count + 1)",
            title: draft.title,
            body: body,
            authorDisplayName: String(
                localized: "community.reply.author.you",
                defaultValue: "你",
                comment: "Reply author"
            ),
            replyCount: 0,
            mediaItems: draft.mediaItems
        )
        userCreatedPosts.insert(detail, at: 0)
        return CommunityPost(
            id: detail.id,
            title: draft.title,
            excerpt: String(body.prefix(80)),
            authorDisplayName: detail.authorDisplayName,
            replyCount: 0
        )
    }

    public func createRecapPost(_ draft: CommunityRecapDraft) async throws -> CommunityPostDetail {
        try CommunityRecapDraft.validate(draft)
        let detail = CommunityPostDetail(
            id: "cp_recap_\(userCreatedPosts.count + 1)",
            title: draft.postTitle,
            body: draft.normalizedBody,
            authorDisplayName: String(
                localized: "community.reply.author.you",
                defaultValue: "你",
                comment: "Reply author"
            ),
            replyCount: 0,
            linkedActivity: LinkedActivityContext(id: draft.activityID, name: draft.activityTitle),
            mediaItems: draft.publishedMedia,
            kind: .activityRecap
        )
        userCreatedPosts.insert(detail, at: 0)
        return detail
    }

    public func createReply(postID: String, body: String) async throws -> CommunityPostReply {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw CommunityError.underlying(.unknown(message: "body required"))
        }
        let reply = CommunityPostReply(
            id: "cpr_mock_\(replyStore[postID, default: []].count + 1)",
            body: trimmed,
            authorDisplayName: String(
                localized: "community.reply.author.you",
                defaultValue: "你",
                comment: "Reply author"
            ),
            createdAt: Date()
        )
        replyStore[postID, default: []].append(reply)
        return reply
    }

    public func reportPost(
        postID: String,
        reason: CommunityReportReason,
        detail: String?
    ) async throws {
        _ = postID
        _ = reason
        _ = detail
    }

    public func setPostLike(postID: String, liked: Bool) async throws -> CommunityPostLikeResult {
        guard postExists(postID: postID) else {
            throw CommunityError.underlying(.server(statusCode: 404, message: nil))
        }
        ensureCatalogLikeCount(for: postID)
        if liked {
            viewerLikedPostIDs.insert(postID)
        } else {
            viewerLikedPostIDs.remove(postID)
        }
        return likeResult(for: postID)
    }

    private func postExists(postID: String) -> Bool {
        MockCommunityTabCatalog.feedPosts().contains { $0.id == postID }
            || allPostDetails().contains { $0.id == postID }
    }

    private func ensureCatalogLikeCount(for postID: String) {
        guard catalogLikeCounts[postID] == nil else { return }
        if let feedPost = MockCommunityTabCatalog.feedPosts().first(where: { $0.id == postID }) {
            catalogLikeCounts[postID] = feedPost.likeCount
            return
        }
        if let detail = allPostDetails().first(where: { $0.id == postID }) {
            catalogLikeCounts[postID] = detail.likeCount
        }
    }

    private func likeResult(for postID: String) -> CommunityPostLikeResult {
        let base = catalogLikeCounts[postID] ?? 0
        let viewerHasLiked = viewerLikedPostIDs.contains(postID)
        return CommunityPostLikeResult(
            viewerHasLiked: viewerHasLiked,
            likeCount: base + (viewerHasLiked ? 1 : 0)
        )
    }

    private func applyLikeState(to post: CommunityFeedPost) -> CommunityFeedPost {
        ensureCatalogLikeCount(for: post.id)
        let result = likeResult(for: post.id)
        return CommunityFeedPost(
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
    }

    private func applyLikeState(to detail: CommunityPostDetail) -> CommunityPostDetail {
        ensureCatalogLikeCount(for: detail.id)
        let result = likeResult(for: detail.id)
        return CommunityPostDetail(
            id: detail.id,
            title: detail.title,
            body: detail.body,
            authorDisplayName: detail.authorDisplayName,
            authorUserID: detail.authorUserID,
            replyCount: detail.replyCount,
            replies: detail.replies,
            linkedActivity: detail.linkedActivity,
            mediaItems: detail.mediaItems,
            tags: detail.tags,
            kind: detail.kind,
            likeCount: result.likeCount,
            viewerHasLiked: result.viewerHasLiked
        )
    }

    private func applyLikeState(to experience: CommunityTabExperience) -> CommunityTabExperience {
        let items = experience.feedItems.map { item -> CommunityFeedItem in
            guard case .post(let post) = item else { return item }
            return .post(applyLikeState(to: post))
        }
        return CommunityTabExperience(
            joinedCommunities: experience.joinedCommunities,
            feedItems: items,
            allCommunities: experience.allCommunities
        )
    }
}
