// Module: SparkCommunity — Community feed boundary.

import Foundation

public protocol CommunityPostsRepository: Sendable {
    func fetchPosts() async throws -> [CommunityPost]
    func fetchPost(id: String) async throws -> CommunityPostDetail
}
