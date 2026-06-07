// Module: SparkCommunityTests

import SparkCommunity
import Testing

@Suite(.serialized)
@MainActor
struct CommunityRootViewTests {
    @Test func rootViewInitializes() {
        _ = CommunityRootView(coordinator: CommunityCoordinator(repository: MockCommunityPostsRepository()))
    }
}
