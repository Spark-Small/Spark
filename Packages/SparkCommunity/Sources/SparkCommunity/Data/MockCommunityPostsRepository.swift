// Module: SparkCommunity — Mock community feed.

import Foundation

public actor MockCommunityPostsRepository: CommunityPostsRepository {
    private var replyStore: [String: [CommunityPostReply]]

    public init() {
        replyStore = MockCommunityPostCatalog.defaultReplies()
    }

    public init(replyStore: [String: [CommunityPostReply]]) {
        self.replyStore = replyStore
    }

    public func fetchPosts() async throws -> [CommunityPost] {
        MockCommunityPostCatalog.allPosts(replyStore: replyStore).map(MockCommunityPostCatalog.summary)
    }

    public func fetchTabExperience() async throws -> CommunityTabExperience {
        MockCommunityTabCatalog.tabExperience()
    }

    public func fetchPost(id: String) async throws -> CommunityPostDetail {
        guard let post = MockCommunityPostCatalog.allPosts(replyStore: replyStore).first(where: { $0.id == id }) else {
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
}
