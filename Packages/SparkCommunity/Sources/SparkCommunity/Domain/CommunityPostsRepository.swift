// Module: SparkCommunity — Community feed boundary.

import Foundation

public protocol CommunityPostsRepository: Sendable {
    func fetchPosts() async throws -> [CommunityPost]
    func fetchPost(id: String) async throws -> CommunityPostDetail
    func fetchTabExperience() async throws -> CommunityTabExperience
    func fetchCommunityDetail(id: String) async throws -> CommunityDetail
    func joinCommunity(id: String) async throws -> CommunityDetail
    func fetchCommunityActivities(communityID: String) async throws -> [CommunityLinkedActivity]
    func fetchCommunityMembers(communityID: String) async throws -> [CommunityMember]
    func fetchCommunityPosts(communityID: String) async throws -> [CommunityFeedPost]
    func createPost(_ draft: CreateCommunityPostDraft) async throws -> CommunityPost
    func createReply(postID: String, body: String) async throws -> CommunityPostReply
}
