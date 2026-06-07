// Module: SparkSearch — UseCase protocols for ViewModel testability.

import Foundation

public protocol SearchQueryUseCaseProtocol: Sendable {
    func callAsFunction(query: String) async throws -> [SearchResultItem]
}

extension SearchQueryUseCase: SearchQueryUseCaseProtocol {}
