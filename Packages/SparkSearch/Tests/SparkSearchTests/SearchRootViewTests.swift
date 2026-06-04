// Module: SparkSearchTests

import SparkSearch
import Testing

@Suite(.serialized)
@MainActor
struct SearchRootViewTests {
    @Test func rootViewInitializes() {
        _ = SearchRootView(repository: MockSearchRepository(), initialQuery: "spark")
    }
}
