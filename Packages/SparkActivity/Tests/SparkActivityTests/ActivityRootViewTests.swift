// Module: SparkActivityTests

import SparkActivity
import Testing

@Suite(.serialized)
@MainActor
struct ActivityRootViewTests {
    @Test func rootViewInitializes() {
        _ = ActivityRootView(repository: MockActivityFeedRepository())
    }
}
