// Module: SparkProfile — Tab-level ViewModel factory (trust + search).

import SparkSearch
import SparkTrust

public struct ProfileCoordinator: Sendable {
    private let profileRepository: any ProfileRepository
    private let userContextRepository: any UserContextRepository
    private let trustCoordinator: TrustCoordinator
    private let searchCoordinator: SearchCoordinator

    public init(
        trustRepository: any TrustRepository,
        searchRepository: any SearchRepository,
        userContextRepository: any UserContextRepository
    ) {
        profileRepository = TrustBackedProfileRepository(trustRepository: trustRepository)
        self.userContextRepository = userContextRepository
        trustCoordinator = TrustCoordinator(repository: trustRepository)
        searchCoordinator = SearchCoordinator(repository: searchRepository)
    }

    public func makeFetchUserContextUseCase() -> FetchUserContextUseCase {
        FetchUserContextUseCase(repository: userContextRepository)
    }

    @MainActor
    public func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(
            fetchProfileSummary: FetchProfileSummaryUseCase(repository: profileRepository)
        )
    }

    @MainActor
    public func makeVerificationViewModel(onCompleted: (() -> Void)? = nil) -> TrustVerificationViewModel {
        trustCoordinator.makeVerificationViewModel(onCompleted: onCompleted)
    }

    public func makeSearchCoordinator() -> SearchCoordinator {
        searchCoordinator
    }
}
