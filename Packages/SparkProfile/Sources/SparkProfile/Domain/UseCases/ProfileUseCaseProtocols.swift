// Module: SparkProfile — UseCase protocols for ViewModel testability.

import Foundation

public protocol FetchProfileSummaryUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> ProfileSummary
}

extension FetchProfileSummaryUseCase: FetchProfileSummaryUseCaseProtocol {}
