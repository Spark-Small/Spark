import Foundation
import Testing
@testable import SparkActivity

@MainActor
struct ActivityBrowseJoinViewModelTests {
    @Test func confirmJoinSetsGoingStatus() async throws {
        let item = ActivityItem(
            id: "act_1",
            title: "Hike",
            summary: "",
            category: "户外",
            startsAt: Date(),
            locationName: "Park",
            hostDisplayName: "Host",
            attendeeCount: 2,
            capacity: 8,
            rsvpStatus: .invited
        )
        let viewModel = ActivityBrowseJoinViewModel(
            item: item,
            updateRSVP: UpdateActivityRSVPUseCase(repository: MockActivityFeedRepository())
        )

        let detail = try await viewModel.confirmJoin()

        #expect(detail.rsvpStatus == .going)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func confirmJoinSurfacesActivityError() async {
        let item = ActivityItem(
            id: "missing",
            title: "Missing",
            summary: "",
            category: "户外",
            startsAt: Date(),
            locationName: "Park",
            hostDisplayName: "Host",
            attendeeCount: 2,
            capacity: 8,
            rsvpStatus: .invited
        )
        let viewModel = ActivityBrowseJoinViewModel(
            item: item,
            updateRSVP: UpdateActivityRSVPUseCase(repository: MockActivityFeedRepository())
        )

        do {
            _ = try await viewModel.confirmJoin()
            Issue.record("Expected join to fail for missing activity")
        } catch {
            #expect(viewModel.errorMessage != nil)
            #expect(viewModel.isSubmitting == false)
        }
    }

    @Test func clearErrorResetsMessage() {
        let item = ActivityItem(
            id: "act_1",
            title: "Hike",
            summary: "",
            category: "户外"
        )
        let viewModel = ActivityBrowseJoinViewModel(
            item: item,
            updateRSVP: UpdateActivityRSVPUseCase(repository: MockActivityFeedRepository())
        )
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
}
