// Module: SparkCommunity — ViewModel factory; keeps Repository out of SwiftUI Views.

import Foundation

public struct CommunityCoordinator: Sendable {
    private let repository: any CommunityPostsRepository

    public init(repository: any CommunityPostsRepository) {
        self.repository = repository
    }

    @MainActor
    public func makeTabViewModel() -> CommunityViewModel {
        CommunityViewModel(
            fetchPosts: FetchCommunityPostsUseCase(repository: repository),
            fetchTabExperience: FetchCommunityTabExperienceUseCase(repository: repository),
            createRecap: CreateCommunityRecapUseCase(repository: repository)
        )
    }

    @MainActor
    public func makeDetailViewModel(communityID: String) -> CommunityDetailViewModel {
        CommunityDetailViewModel(
            communityID: communityID,
            fetchDetailBundle: FetchCommunityDetailBundleUseCase(repository: repository)
        )
    }

    @MainActor
    public func makePostDetailViewModel(postID: String) -> CommunityPostDetailViewModel {
        CommunityPostDetailViewModel(
            postID: postID,
            fetchPost: FetchCommunityPostUseCase(repository: repository),
            createReply: CreateCommunityReplyUseCase(repository: repository),
            reportPost: ReportCommunityPostUseCase(repository: repository)
        )
    }
}
