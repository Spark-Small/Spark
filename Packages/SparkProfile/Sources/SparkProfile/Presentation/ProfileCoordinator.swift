// Module: SparkProfile — Tab-level ViewModel factory (trust + search).

import SparkSearch
import SparkTrust

public struct ProfileCoordinator: Sendable {
    private let profileRepository: any ProfileRepository
    private let trustCoordinator: TrustCoordinator
    private let searchCoordinator: SearchCoordinator

    public init(
        trustRepository: any TrustRepository,
        searchRepository: any SearchRepository
    ) {
        profileRepository = TrustBackedProfileRepository(trustRepository: trustRepository)
        trustCoordinator = TrustCoordinator(repository: trustRepository)
        searchCoordinator = SearchCoordinator(repository: searchRepository)
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
