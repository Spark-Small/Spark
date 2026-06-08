// Module: SparkActivity — Activity list data boundary.

import Foundation

/// Activity feed and invitation operations (Mock + Live).
public protocol ActivityFeedRepository: Sendable {
    func fetchActivities() async throws -> [ActivityItem]
    func fetchActivitiesByHost(hostID: String, excludingActivityID: String?) async throws -> [ActivityItem]
    func fetchActivity(id: String) async throws -> ActivityDetail
    func updateRSVP(activityID: String, status: ActivityRSVPStatus) async throws -> ActivityDetail
    func createActivity(_ draft: CreateActivityDraft) async throws -> ActivityDetail
    func updateActivity(activityID: String, draft: CreateActivityDraft) async throws -> ActivityDetail
    func cancelActivity(activityID: String) async throws -> ActivityDetail
    func reportActivity(activityID: String, reason: ActivityReportReason) async throws -> ActivityReportResult
    func joinWaitlist(activityID: String) async throws -> ActivityDetail
    func promoteFromWaitlist(activityID: String, attendeeID: String) async throws -> ActivityDetail
    func reviewAttendee(
        activityID: String,
        attendeeID: String,
        decision: AttendeeReviewDecision
    ) async throws -> ActivityDetail
    func assignCohost(activityID: String, attendeeID: String) async throws -> ActivityDetail
    func announceActivity(activityID: String, message: String) async throws
    func submitHostFeedback(activityID: String, feedback: ActivityHostFeedback) async throws
}
