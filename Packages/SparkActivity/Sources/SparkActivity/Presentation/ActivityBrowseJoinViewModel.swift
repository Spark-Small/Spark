// Module: SparkActivity — Discover feed join confirmation state.

import Foundation
import SparkCore

@MainActor
@Observable
final class ActivityBrowseJoinViewModel {
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    let item: ActivityItem
    let summary: ActivityBrowseJoinSummary

    private let updateRSVP: UpdateActivityRSVPUseCase

    init(item: ActivityItem, updateRSVP: UpdateActivityRSVPUseCase) {
        self.item = item
        self.summary = ActivityBrowseJoinSummary(item: item)
        self.updateRSVP = updateRSVP
    }

    func clearError() {
        errorMessage = nil
    }

    func confirmJoin() async throws -> ActivityDetail {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let detail = try await updateRSVP(activityID: item.id, status: .going)
            IntegrationTelemetry.browseToRSVP(activityID: item.id)
            IntegrationTelemetry.rsvpCompleted(source: "browse_sheet", activityID: item.id)
            await ActivityLocalReminderScheduler.syncReminders(for: detail)
            return detail
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as ActivityError {
            errorMessage = error.errorDescription
            throw error
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
}
