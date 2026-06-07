// Module: SparkActivity — Preview/test stubs for `ActivityFeedRepository`.

import Foundation

/// Empty feed for SwiftUI previews and empty-state tests.
struct EmptyActivityFeedRepository: ActivityFeedRepository, Sendable {
    func fetchActivities() async throws -> [ActivityItem] { [] }

    func fetchActivitiesByHost(hostID: String, excludingActivityID: String?) async throws -> [ActivityItem] { [] }

    func fetchActivity(id: String) async throws -> ActivityDetail {
        throw StubError.notFound
    }

    func updateRSVP(activityID: String, status: ActivityRSVPStatus) async throws -> ActivityDetail {
        throw StubError.notFound
    }

    func createActivity(_ draft: CreateActivityDraft) async throws -> ActivityDetail {
        throw StubError.notFound
    }

    func updateActivity(activityID: String, draft: CreateActivityDraft) async throws -> ActivityDetail {
        throw StubError.notFound
    }

    func cancelActivity(activityID: String) async throws -> ActivityDetail {
        throw StubError.notFound
    }

    func reportActivity(activityID: String, reason: ActivityReportReason) async throws -> ActivityReportResult {
        throw StubError.notFound
    }

    func joinWaitlist(activityID: String) async throws -> ActivityDetail {
        throw StubError.notFound
    }

    func promoteFromWaitlist(activityID: String, attendeeID: String) async throws -> ActivityDetail {
        throw StubError.notFound
    }

    func reviewAttendeeRSVP(activityID: String, attendeeID: String, approve: Bool) async throws -> ActivityDetail {
        throw StubError.notFound
    }

    func setAttendeeCoHost(activityID: String, attendeeID: String, isCoHost: Bool) async throws -> ActivityDetail {
        throw StubError.notFound
    }

    func announceActivity(activityID: String, message: String) async throws {
        throw StubError.notFound
    }

    func submitHostFeedback(activityID: String, feedback: ActivityHostFeedback) async throws {
        throw StubError.notFound
    }

    enum StubError: LocalizedError {
        case notFound

        var errorDescription: String? {
            switch self {
            case .notFound: "Not found"
            }
        }
    }
}

/// Failing feed for error-state previews and tests.
struct FailingActivityFeedRepository: ActivityFeedRepository, Sendable {
    func fetchActivities() async throws -> [ActivityItem] {
        throw StubError.unavailable
    }

    func fetchActivitiesByHost(hostID: String, excludingActivityID: String?) async throws -> [ActivityItem] {
        throw StubError.unavailable
    }

    func fetchActivity(id: String) async throws -> ActivityDetail {
        throw StubError.unavailable
    }

    func updateRSVP(activityID: String, status: ActivityRSVPStatus) async throws -> ActivityDetail {
        throw StubError.unavailable
    }

    func createActivity(_ draft: CreateActivityDraft) async throws -> ActivityDetail {
        throw StubError.unavailable
    }

    func updateActivity(activityID: String, draft: CreateActivityDraft) async throws -> ActivityDetail {
        throw StubError.unavailable
    }

    func cancelActivity(activityID: String) async throws -> ActivityDetail {
        throw StubError.unavailable
    }

    func reportActivity(activityID: String, reason: ActivityReportReason) async throws -> ActivityReportResult {
        throw StubError.unavailable
    }

    func joinWaitlist(activityID: String) async throws -> ActivityDetail {
        throw StubError.unavailable
    }

    func promoteFromWaitlist(activityID: String, attendeeID: String) async throws -> ActivityDetail {
        throw StubError.unavailable
    }

    func reviewAttendeeRSVP(activityID: String, attendeeID: String, approve: Bool) async throws -> ActivityDetail {
        throw StubError.unavailable
    }

    func setAttendeeCoHost(activityID: String, attendeeID: String, isCoHost: Bool) async throws -> ActivityDetail {
        throw StubError.unavailable
    }

    func announceActivity(activityID: String, message: String) async throws {
        throw StubError.unavailable
    }

    func submitHostFeedback(activityID: String, feedback: ActivityHostFeedback) async throws {
        throw StubError.unavailable
    }

    enum StubError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            switch self {
            case .unavailable: "Feed unavailable"
            }
        }
    }
}
