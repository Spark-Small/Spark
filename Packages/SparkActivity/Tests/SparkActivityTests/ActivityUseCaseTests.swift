// Module: SparkActivityTests — Activity use case coverage.

@testable import SparkActivity
import Testing

struct ActivityUseCaseTests {
    @Test func fetchActivityFeedUseCaseReturnsSeedItems() async throws {
        let useCase = FetchActivityFeedUseCase(repository: MockActivityFeedRepository())
        let items = try await useCase()
        #expect(!items.isEmpty)
    }

    @Test func fetchActivityBrowsePageUseCaseReturnsItems() async throws {
        let useCase = FetchActivityBrowsePageUseCase(repository: MockActivityBrowseRepository())
        let page = try await useCase(query: ActivityBrowseQuery())
        #expect(page.items.count >= 2)
    }

    @Test func fetchActivityDetailUseCaseReturnsDetail() async throws {
        let useCase = FetchActivityDetailUseCase(repository: MockActivityFeedRepository())
        let detail = try await useCase(activityID: "act_1")
        #expect(detail.id == "act_1")
    }

    @Test func createActivityUseCaseCreatesItem() async throws {
        let repository = MockActivityFeedRepository()
        let useCase = CreateActivityUseCase(repository: repository)
        var draft = CreateActivityDraft()
        draft.title = "Test"
        draft.description = "Summary"
        draft.locationName = "Shanghai"
        draft.capacity = 4
        let detail = try await useCase(draft: draft)
        #expect(detail.title == "Test")
    }
}
