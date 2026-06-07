// Module: SparkTrust — UseCase protocols for ViewModel testability.

import Foundation

public protocol FetchTrustProfileUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> TrustProfile
}

public protocol VerifyTrustLevelUseCaseProtocol: Sendable {
    func callAsFunction(_ level: TrustLevel) async throws -> TrustProfile
}

extension FetchTrustProfileUseCase: FetchTrustProfileUseCaseProtocol {}
extension VerifyTrustLevelUseCase: VerifyTrustLevelUseCaseProtocol {}
