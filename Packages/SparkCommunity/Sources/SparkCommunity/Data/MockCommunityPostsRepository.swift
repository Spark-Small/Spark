// Module: SparkCommunity — Mock community feed.

import Foundation

public struct MockCommunityPostsRepository: CommunityPostsRepository, Sendable {
    public init() {}

    public func fetchPosts() async throws -> [CommunityPost] {
        MockCommunityPostCatalog.allPosts().map(MockCommunityPostCatalog.summary)
    }

    public func fetchPost(id: String) async throws -> CommunityPostDetail {
        guard let post = MockCommunityPostCatalog.allPosts().first(where: { $0.id == id }) else {
            throw CommunityError.underlying(.server(statusCode: 404, message: nil))
        }
        return post
    }
}
