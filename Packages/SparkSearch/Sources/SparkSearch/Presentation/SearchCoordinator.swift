// Module: SparkSearch — ViewModel factory; keeps Repository out of SwiftUI Views.

import Foundation

public struct SearchCoordinator: Sendable {
    private let repository: any SearchRepository

    public init(repository: any SearchRepository) {
        self.repository = repository
    }

    @MainActor
    public func makeViewModel(initialQuery: String = "") -> SearchViewModel {
        let viewModel = SearchViewModel(searchQuery: SearchQueryUseCase(repository: repository))
        viewModel.query = initialQuery
        return viewModel
    }
}
