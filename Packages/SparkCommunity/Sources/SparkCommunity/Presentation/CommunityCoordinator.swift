// Module: SparkCommunity — ViewModel factory; keeps Repository out of SwiftUI Views.

import Foundation

public struct CommunityCoordinator: Sendable {
    private let repository: any CommunityPostsRepository
    private let prepareMediaUpload: any PrepareCommunityMediaUploadUseCaseProtocol

    public init(
        repository: any CommunityPostsRepository,
        prepareMediaUpload: any PrepareCommunityMediaUploadUseCaseProtocol = PrepareCommunityMediaUploadUseCase()
    ) {
        self.repository = repository
        self.prepareMediaUpload = prepareMediaUpload
    }

    @MainActor
    public func makeTabViewModel() -> CommunityViewModel {
        CommunityViewModel(
            fetchPosts: FetchCommunityPostsUseCase(repository: repository),
            fetchTabExperience: FetchCommunityTabExperienceUseCase(repository: repository),
            createRecap: CreateCommunityRecapUseCase(repository: repository),
            createPost: CreateCommunityPostUseCase(repository: repository)
        )
    }

    @MainActor
    public func makeCreatePostViewModel() -> CreateCommunityPostViewModel {
        CreateCommunityPostViewModel(
            createPost: CreateCommunityPostUseCase(repository: repository),
            prepareMediaUpload: prepareMediaUpload
        )
    }

    @MainActor
    public func makeDetailViewModel(communityID: String) -> CommunityDetailViewModel {
        CommunityDetailViewModel(
            communityID: communityID,
            fetchDetailBundle: FetchCommunityDetailBundleUseCase(repository: repository),
            joinCommunity: JoinCommunityUseCase(repository: repository)
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
