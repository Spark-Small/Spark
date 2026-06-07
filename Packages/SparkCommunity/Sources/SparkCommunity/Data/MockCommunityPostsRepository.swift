// Module: SparkCommunity — Mock community feed.

import Foundation

public actor MockCommunityPostsRepository: CommunityPostsRepository {
    private var replyStore: [String: [CommunityPostReply]]
    private var userCreatedPosts: [CommunityPostDetail] = []
    private var joinedCommunityIDs: Set<String>

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
        MockCommunityTabCatalog.tabExperience(joinedIDs: joinedCommunityIDs)
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
            return post
        }
        if let feedPost = MockCommunityTabCatalog.feedPosts().first(where: { $0.id == id }) {
            let replies = replyStore[id, default: []]
            return MockCommunityTabCatalog.postDetail(for: feedPost, replies: replies)
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
            mediaItems: draft.publishedMedia
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
}
