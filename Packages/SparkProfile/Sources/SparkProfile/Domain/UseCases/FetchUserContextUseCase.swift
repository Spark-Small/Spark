// Module: SparkProfile — Load cross-tab user context.

import Foundation

public protocol FetchUserContextUseCaseProtocol: Sendable {
    func callAsFunction(userID: String) async throws -> UserContext
}

public struct FetchUserContextUseCase: FetchUserContextUseCaseProtocol, Sendable {
    private let repository: any UserContextRepository

    public init(repository: any UserContextRepository) {
        self.repository = repository
    }

    public func callAsFunction(userID: String) async throws -> UserContext {
        try await repository.fetchContext(userID: userID)
    }
}
