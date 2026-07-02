// Module: SparkActivity — Mock activity list for previews and mock API host.

import Foundation
import os

public actor MockActivityFeedRepository: ActivityFeedRepository {
    private let logger = Logger(subsystem: "com.spark.activity", category: "MockActivityFeed")
    private let blockedHostsStore: BlockedActivityHostsStore

    private var rsvpOverrides: [String: ActivityRSVPStatus] = [:]
    private var hostEdits: [String: ActivityDetail] = [:]
    private var cancelledIDs: Set<String> = []
    private var hostCreated: [ActivityDetail] = []

    public init(blockedHostsStore: BlockedActivityHostsStore = BlockedActivityHostsStore()) {
        self.blockedHostsStore = blockedHostsStore
    }

    public func fetchActivities() async throws -> [ActivityItem] {
        let items = mergedDetails().map { $0.asListItem() }
        var visible: [ActivityItem] = []
        for item in items {
            if await !blockedHostsStore.isBlocked(hostID: item.hostID) {
                visible.append(item)
            }
        }
        return visible
    }

    public func fetchActivitiesByHost(hostID: String, excludingActivityID: String?) async throws -> [ActivityItem] {
        mergedDetails()
            .filter { $0.hostID == hostID && $0.id != excludingActivityID }
            .map { $0.asListItem() }
            .sorted { ($0.startsAt ?? .distantFuture) < ($1.startsAt ?? .distantFuture) }
    }

    public func fetchActivity(id: String) async throws -> ActivityDetail {
        guard let detail = mergedDetails().first(where: { $0.id == id }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        return detail
    }

    public func updateRSVP(activityID: String, status: ActivityRSVPStatus) async throws -> ActivityDetail {
        guard ActivityRSVPStatus.selectableResponses.contains(status) else {
            throw ActivityError.underlying(.unknown(message: "Invalid RSVP status"))
        }
        guard var detail = mergedDetails().first(where: { $0.id == activityID }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        if status == .going,
           !ActivityRegistrationRules.canSelectGoing(
               attendeeCount: detail.attendeeCount,
               capacity: detail.capacity,
               rsvpStatus: detail.rsvpStatus,
               lifecycleStatus: detail.lifecycleStatus
           ) {
            throw ActivityError.activityFull
        }
        rsvpOverrides[activityID] = status
        detail = detail.updatingRSVP(status)
        if status == .going || status == .maybe {
            detail = detail.updatingThreadID(ActivityThreadID.make(for: activityID))
        }
        if status == .going,
           let capacity = detail.capacity,
           detail.attendeeCount < capacity {
            detail = detail.updatingAttendeeCount(detail.attendeeCount + 1)
        }
        persistHostEdit(detail)
        return detail
    }

    public func createActivity(_ draft: CreateActivityDraft) async throws -> ActivityDetail {
        try CreateActivityDraft.validate(draft)
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw ActivityError.underlying(.unknown(message: "Title required"))
        }
        let id = "act_\(UUID().uuidString.prefix(8))"
        let hostName = String(localized: "activity.host.you", defaultValue: "你", comment: "Current user as host")
        let category = draft.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? String(localized: "activity.category.event", defaultValue: "活动", comment: "Activity category")
            : draft.category.trimmingCharacters(in: .whitespacesAndNewlines)
        let detail = ActivityDetail(
            id: id,
            title: trimmedTitle,
            summary: ActivityFormatting.scheduleLine(startsAt: draft.startsAt, locationName: draft.locationName),
            category: category,
            description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
            startsAt: draft.startsAt,
            locationName: draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines),
            hostDisplayName: hostName,
            hostID: "host_me",
            hostBio: nil,
            attendeeCount: 1,
            capacity: draft.capacity,
            rsvpStatus: .host,
            lifecycleStatus: .scheduled,
            attendees: MockActivityAttendees.roster(host: hostName, members: [String]()),
            conversationThreadID: ActivityThreadID.make(for: id),
            coverURL: draft.coverURL,
            coverPosterURL: draft.coverPosterURL,
            coverIsVideo: draft.coverIsVideo
        )
        hostCreated.insert(detail, at: 0)
        return detail
    }

    public func updateActivity(activityID: String, draft: CreateActivityDraft) async throws -> ActivityDetail {
        try CreateActivityDraft.validate(draft)
        guard draft.isValid else {
            throw ActivityError.underlying(.unknown(message: "Invalid activity draft"))
        }
        guard var detail = mergedDetails().first(where: { $0.id == activityID }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        guard detail.rsvpStatus == .host else {
            throw ActivityError.underlying(.server(statusCode: 403, message: nil))
        }
        guard detail.lifecycleStatus == .scheduled else {
            throw ActivityError.underlying(.unknown(message: "Activity not editable"))
        }
        detail = detail.updating(from: draft)
        persistHostEdit(detail)
        if let index = hostCreated.firstIndex(where: { $0.id == activityID }) {
            hostCreated[index] = detail
        }
        return detail
    }

    public func cancelActivity(activityID: String) async throws -> ActivityDetail {
        guard var detail = mergedDetails().first(where: { $0.id == activityID }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        guard detail.rsvpStatus == .host else {
            throw ActivityError.underlying(.server(statusCode: 403, message: nil))
        }
        cancelledIDs.insert(activityID)
        detail = detail.updatingLifecycle(.cancelled)
        persistHostEdit(detail)
        return detail
    }

    public func reportActivity(activityID: String, reason: ActivityReportReason) async throws -> ActivityReportResult {
        guard let detail = mergedDetails().first(where: { $0.id == activityID }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        logger.info("Activity reported id=\(activityID, privacy: .public) reason=\(reason.rawValue, privacy: .public)")
        if let hostID = detail.hostID {
            await blockedHostsStore.block(hostID: hostID)
        }
        return ActivityReportResult(reportID: "rpt_\(UUID().uuidString.prefix(8))")
    }

    public func joinWaitlist(activityID: String) async throws -> ActivityDetail {
        guard var detail = mergedDetails().first(where: { $0.id == activityID }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        guard detail.canJoinWaitlist else {
            throw ActivityError.underlying(.unknown(message: "Waitlist not available"))
        }
        rsvpOverrides[activityID] = .waitlisted
        detail = detail.updatingRSVP(.waitlisted).updatingWaitlistedCount(detail.waitlistedCount + 1)
        persistHostEdit(detail)
        return detail
    }

    public func promoteFromWaitlist(activityID: String, attendeeID: String) async throws -> ActivityDetail {
        guard var detail = mergedDetails().first(where: { $0.id == activityID }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        guard detail.rsvpStatus == .host else {
            throw ActivityError.underlying(.server(statusCode: 403, message: nil))
        }
        var attendees = detail.attendees
        guard let index = attendees.firstIndex(where: { $0.id == attendeeID && $0.rsvpStatus == .waitlisted }) else {
            throw ActivityError.underlying(.unknown(message: "Waitlisted attendee not found"))
        }
        let member = attendees[index]
        attendees[index] = ActivityAttendee(
            id: member.id,
            displayName: member.displayName,
            isHost: false,
            rsvpStatus: .going,
            isVerified: member.isVerified,
            isCoHost: member.isCoHost
        )
        detail = detail.updatingAttendees(
            attendees,
            attendeeCount: detail.attendeeCount + 1,
            waitlistedCount: max(0, detail.waitlistedCount - 1)
        )
        persistHostEdit(detail)
        return detail
    }

    public func reviewAttendeeRSVP(activityID: String, attendeeID: String, approve: Bool) async throws -> ActivityDetail {
        if approve {
            guard let detail = mergedDetails().first(where: { $0.id == activityID }),
                  let attendee = detail.attendees.first(where: { $0.id == attendeeID }) else {
                throw ActivityError.underlying(.server(statusCode: 404, message: nil))
            }
            if attendee.rsvpStatus == .waitlisted {
                return try await promoteFromWaitlist(activityID: activityID, attendeeID: attendeeID)
            }
            return try await replaceAttendeeStatus(activityID: activityID, attendeeID: attendeeID, status: .going)
        }
        return try await replaceAttendeeStatus(activityID: activityID, attendeeID: attendeeID, status: .declined)
    }

    public func setAttendeeCoHost(activityID: String, attendeeID: String, isCoHost: Bool) async throws -> ActivityDetail {
        guard var detail = mergedDetails().first(where: { $0.id == activityID }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        guard detail.rsvpStatus == .host else {
            throw ActivityError.underlying(.server(statusCode: 403, message: nil))
        }
        var attendees = detail.attendees
        guard let index = attendees.firstIndex(where: { $0.id == attendeeID && !$0.isHost }) else {
            throw ActivityError.underlying(.unknown(message: "Attendee not found"))
        }
        let member = attendees[index]
        attendees[index] = ActivityAttendee(
            id: member.id,
            displayName: member.displayName,
            isHost: false,
            rsvpStatus: member.rsvpStatus,
            isVerified: member.isVerified,
            isCoHost: isCoHost
        )
        detail = detail.updatingAttendees(attendees)
        persistHostEdit(detail)
        return detail
    }

    private func replaceAttendeeStatus(
        activityID: String,
        attendeeID: String,
        status: ActivityRSVPStatus
    ) async throws -> ActivityDetail {
        guard var detail = mergedDetails().first(where: { $0.id == activityID }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        guard detail.rsvpStatus == .host else {
            throw ActivityError.underlying(.server(statusCode: 403, message: nil))
        }
        var attendees = detail.attendees
        guard let index = attendees.firstIndex(where: { $0.id == attendeeID && !$0.isHost }) else {
            throw ActivityError.underlying(.unknown(message: "Attendee not found"))
        }
        let member = attendees[index]
        attendees[index] = ActivityAttendee(
            id: member.id,
            displayName: member.displayName,
            isHost: false,
            rsvpStatus: status,
            isVerified: member.isVerified,
            isCoHost: member.isCoHost
        )
        detail = detail.updatingAttendees(attendees)
        persistHostEdit(detail)
        return detail
    }

    public func announceActivity(activityID: String, message: String) async throws {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ActivityError.underlying(.unknown(message: "Message required"))
        }
        guard mergedDetails().contains(where: { $0.id == activityID }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        logger.info("Activity announce id=\(activityID, privacy: .public)")
    }

    public func submitHostFeedback(activityID: String, feedback: ActivityHostFeedback) async throws {
        guard mergedDetails().contains(where: { $0.id == activityID }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        logger.info("Activity feedback id=\(activityID, privacy: .public) value=\(feedback.rawValue, privacy: .public)")
    }

    private func mergedDetails() -> [ActivityDetail] {
        let base = hostCreated + MockActivityCatalog.allDetails()
        return base.map { detail in
            var current = hostEdits[detail.id] ?? detail
            if let status = rsvpOverrides[detail.id] {
                current = current.updatingRSVP(status)
                if status.hasGroupChatAccess {
                    current = current.updatingThreadID(ActivityThreadID.make(for: detail.id))
                }
            }
            if cancelledIDs.contains(detail.id) {
                current = current.updatingLifecycle(.cancelled)
            }
            return current
        }
    }

    private func persistHostEdit(_ detail: ActivityDetail) {
        if detail.rsvpStatus == .host || hostEdits[detail.id] != nil {
            hostEdits[detail.id] = detail
        }
    }
}
