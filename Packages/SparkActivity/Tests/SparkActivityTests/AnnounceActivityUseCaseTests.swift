// Module: SparkActivityTests

@testable import SparkActivity
import Testing

struct AnnounceActivityUseCaseTests {
    @Test func emptyMessageThrows() async {
        let useCase = AnnounceActivityUseCase(repository: MockActivityFeedRepository())
        await #expect(throws: ActivityError.emptyInput) {
            try await useCase(activityID: "act_1", message: "   ")
        }
    }
}
