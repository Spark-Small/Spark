// Module: SparkCommunity — Mock community feed.

import Foundation

public actor MockCommunityPostsRepository: CommunityPostsRepository {
    private var replyStore: [String: [CommunityPostReply]]
    private var userCreatedPosts: [CommunityPostDetail] = []

    public init() {
        replyStore = MockCommunityPostCatalog.defaultReplies()
    }

    public init(replyStore: [String: [CommunityPostReply]]) {
        self.replyStore = replyStore
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
        MockCommunityTabCatalog.tabExperience()
    }

    public func fetchCommunityDetail(id: String) async throws -> CommunityDetail {
        guard let detail = MockCommunityDetailCatalog.detail(id: id) else {
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
        guard let post = allPostDetails().first(where: { $0.id == id }) else {
            throw CommunityError.underlying(.server(statusCode: 404, message: nil))
        }
        return post
    }

    public func createPost(_ draft: CreateCommunityPostDraft) async throws -> CommunityPost {
        CommunityPost(
            id: "cp_mock_new",
            title: draft.title,
            excerpt: String(draft.body.prefix(80)),
            authorDisplayName: "你",
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
            linkedActivity: LinkedActivityContext(id: draft.activityID, name: draft.activityTitle)
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
