// Module: SparkTrust — ViewModel factory; keeps Repository out of SwiftUI Views.

import Foundation

public struct TrustCoordinator: Sendable {
    private let repository: any TrustRepository

    public init(repository: any TrustRepository) {
        self.repository = repository
    }

    @MainActor
    public func makeVerificationViewModel(onCompleted: (() -> Void)? = nil) -> TrustVerificationViewModel {
        let viewModel = TrustVerificationViewModel(
            fetchProfile: FetchTrustProfileUseCase(repository: repository),
            verifyLevel: VerifyTrustLevelUseCase(repository: repository)
        )
        viewModel.onCompleted = onCompleted
        return viewModel
    }

    public func makeFetchProfileUseCase() -> any FetchTrustProfileUseCaseProtocol {
        FetchTrustProfileUseCase(repository: repository)
    }
}
