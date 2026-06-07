// Module: SparkSearchTests

import SparkSearch
import Testing

@Suite(.serialized)
@MainActor
struct SearchRootViewTests {
    @Test func rootViewInitializes() {
        _ = SearchRootView(
            coordinator: SearchCoordinator(repository: MockSearchRepository()),
            initialQuery: "spark"
        )
    }
}
