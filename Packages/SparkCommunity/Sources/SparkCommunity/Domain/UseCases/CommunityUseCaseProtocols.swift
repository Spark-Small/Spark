// Module: SparkCommunity — UseCase protocols for ViewModel testability.

import Foundation

public protocol FetchCommunityPostsUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> [CommunityPost]
}

public protocol FetchCommunityTabExperienceUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> CommunityTabExperience
}

public protocol CreateCommunityRecapUseCaseProtocol: Sendable {
    func callAsFunction(_ draft: CommunityRecapDraft) async throws -> CommunityPostDetail
}

public protocol FetchCommunityDetailBundleUseCaseProtocol: Sendable {
    func callAsFunction(communityID: String) async throws -> CommunityDetailBundle
}

public protocol FetchCommunityPostUseCaseProtocol: Sendable {
    func callAsFunction(postID: String) async throws -> CommunityPostDetail
}

public protocol CreateCommunityReplyUseCaseProtocol: Sendable {
    func callAsFunction(postID: String, body: String) async throws -> CommunityPostReply
}

extension FetchCommunityPostsUseCase: FetchCommunityPostsUseCaseProtocol {}
extension FetchCommunityTabExperienceUseCase: FetchCommunityTabExperienceUseCaseProtocol {}
extension CreateCommunityRecapUseCase: CreateCommunityRecapUseCaseProtocol {}
extension FetchCommunityDetailBundleUseCase: FetchCommunityDetailBundleUseCaseProtocol {}
extension FetchCommunityPostUseCase: FetchCommunityPostUseCaseProtocol {}
extension CreateCommunityReplyUseCase: CreateCommunityReplyUseCaseProtocol {}
