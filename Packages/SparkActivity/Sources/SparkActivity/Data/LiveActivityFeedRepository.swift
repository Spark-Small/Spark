// Module: SparkActivity — Network activity list and invitations.

import Foundation
import os
import SparkCore
import SparkNetworking

public struct LiveActivityFeedRepository: ActivityFeedRepository, Sendable {
    private let apiClient: APIClient
    private let logger = Logger(subsystem: SparkLog.subsystem, category: "ActivityFeed")

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchActivities() async throws -> [ActivityItem] {
        do {
            let dto: ActivityFeedResponseDTO = try await apiClient.get(ActivityAPIPath.feed)
            return dto.items.map(ActivityDTOMapper.item)
        } catch {
            throw logAndMap("fetchActivities", error)
        }
    }

    public func fetchActivitiesByHost(hostID: String, excludingActivityID: String?) async throws -> [ActivityItem] {
        do {
            let dto: ActivityFeedResponseDTO = try await apiClient.get(ActivityAPIPath.activitiesByHost(hostID: hostID))
            return dto.items
                .map(ActivityDTOMapper.item)
                .filter { $0.id != excludingActivityID }
        } catch {
            throw logAndMap("fetchActivitiesByHost", error)
        }
    }

    public func fetchActivity(id: String) async throws -> ActivityDetail {
        do {
            let dto: ActivityDetailResponseDTO = try await apiClient.get(ActivityAPIPath.activity(id: id))
            guard let detail = ActivityDTOMapper.detail(from: dto.activity) else {
                throw ActivityError.underlying(.decodingFailed)
            }
            return detail
        } catch {
            throw logAndMap("fetchActivity", error)
        }
    }

    public func createActivity(_ draft: CreateActivityDraft) async throws -> ActivityDetail {
        do {
            let request = CreateActivityRequestDTO(
                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
                locationName: draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines),
                startsAt: ActivityFormatting.iso8601String(from: draft.startsAt),
                capacity: draft.capacity,
                coverURL: draft.coverURL?.absoluteString,
                coverPosterURL: draft.coverPosterURL?.absoluteString,
                coverIsVideo: draft.coverIsVideo ? true : nil
            )
            let body = try JSONEncoder().encode(request)
            let dto: ActivityDetailResponseDTO = try await apiClient.post(ActivityAPIPath.create, body: body)
            guard let detail = ActivityDTOMapper.detail(from: dto.activity) else {
                throw ActivityError.underlying(.decodingFailed)
            }
            return detail
        } catch let error as ActivityError {
            throw error
        } catch {
            throw logAndMap("createActivity", error)
        }
    }

    public func updateRSVP(activityID: String, status: ActivityRSVPStatus) async throws -> ActivityDetail {
        do {
            let body = try JSONEncoder().encode(ActivityRSVPRequestDTO(status: status.rawValue))
            let dto: ActivityRSVPResponseDTO = try await apiClient.post(
                ActivityAPIPath.rsvp(id: activityID),
                body: body
            )
            guard let detail = ActivityDTOMapper.detail(from: dto.activity) else {
                throw ActivityError.underlying(.decodingFailed)
            }
            return detail
        } catch {
            throw logAndMap("updateRSVP", error)
        }
    }

    public func updateActivity(activityID: String, draft: CreateActivityDraft) async throws -> ActivityDetail {
        do {
            let request = CreateActivityRequestDTO(
                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
                locationName: draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines),
                startsAt: ActivityFormatting.iso8601String(from: draft.startsAt),
                capacity: draft.capacity,
                coverURL: draft.coverURL?.absoluteString,
                coverPosterURL: draft.coverPosterURL?.absoluteString,
                coverIsVideo: draft.coverIsVideo ? true : nil
            )
            let body = try JSONEncoder().encode(request)
            let dto: ActivityDetailResponseDTO = try await apiClient.patch(
                ActivityAPIPath.activity(id: activityID),
                body: body
            )
            guard let detail = ActivityDTOMapper.detail(from: dto.activity) else {
                throw ActivityError.underlying(.decodingFailed)
            }
            return detail
        } catch let error as ActivityError {
            throw error
        } catch {
            throw logAndMap("updateActivity", error)
        }
    }

    public func cancelActivity(activityID: String) async throws -> ActivityDetail {
        do {
            let dto: ActivityDetailResponseDTO = try await apiClient.post(
                ActivityAPIPath.cancel(id: activityID),
                body: nil
            )
            guard let detail = ActivityDTOMapper.detail(from: dto.activity) else {
                throw ActivityError.underlying(.decodingFailed)
            }
            return detail
        } catch {
            throw logAndMap("cancelActivity", error)
        }
    }

    public func reportActivity(activityID: String, reason: ActivityReportReason) async throws -> ActivityReportResult {
        do {
            let body = try JSONEncoder().encode(ActivityReportRequestDTO(reason: reason.rawValue))
            let dto: ActivityReportResponseDTO = try await apiClient.post(
                ActivityAPIPath.report(id: activityID),
                body: body
            )
            return ActivityReportResult(reportID: dto.reportID)
        } catch {
            throw logAndMap("reportActivity", error)
        }
    }

    public func joinWaitlist(activityID: String) async throws -> ActivityDetail {
        do {
            let dto: ActivityRSVPResponseDTO = try await apiClient.post(
                ActivityAPIPath.waitlist(id: activityID),
                body: nil
            )
            guard let detail = ActivityDTOMapper.detail(from: dto.activity) else {
                throw ActivityError.underlying(.decodingFailed)
            }
            return detail
        } catch {
            throw logAndMap("joinWaitlist", error)
        }
    }

    public func promoteFromWaitlist(activityID: String, attendeeID: String) async throws -> ActivityDetail {
        do {
            let dto: ActivityRSVPResponseDTO = try await apiClient.post(
                ActivityAPIPath.promoteWaitlist(id: activityID, attendeeID: attendeeID),
                body: nil
            )
            guard let detail = ActivityDTOMapper.detail(from: dto.activity) else {
                throw ActivityError.underlying(.decodingFailed)
            }
            return detail
        } catch {
            throw logAndMap("promoteFromWaitlist", error)
        }
    }

    public func reviewAttendeeRSVP(activityID: String, attendeeID: String, approve: Bool) async throws -> ActivityDetail {
        do {
            let body = try JSONEncoder().encode(ActivityAttendeeReviewRequestDTO(approve: approve))
            let dto: ActivityRSVPResponseDTO = try await apiClient.post(
                ActivityAPIPath.reviewAttendeeRSVP(id: activityID, attendeeID: attendeeID),
                body: body
            )
            guard let detail = ActivityDTOMapper.detail(from: dto.activity) else {
                throw ActivityError.underlying(.decodingFailed)
            }
            return detail
        } catch {
            throw logAndMap("reviewAttendeeRSVP", error)
        }
    }

    public func setAttendeeCoHost(activityID: String, attendeeID: String, isCoHost: Bool) async throws -> ActivityDetail {
        do {
            let body = try JSONEncoder().encode(ActivityAttendeeCoHostRequestDTO(isCoHost: isCoHost))
            let dto: ActivityRSVPResponseDTO = try await apiClient.patch(
                ActivityAPIPath.setAttendeeCoHost(id: activityID, attendeeID: attendeeID),
                body: body
            )
            guard let detail = ActivityDTOMapper.detail(from: dto.activity) else {
                throw ActivityError.underlying(.decodingFailed)
            }
            return detail
        } catch {
            throw logAndMap("setAttendeeCoHost", error)
        }
    }

    public func announceActivity(activityID: String, message: String) async throws {
        do {
            let body = try JSONEncoder().encode(ActivityAnnounceRequestDTO(message: message))
            try await apiClient.post(ActivityAPIPath.announce(id: activityID), body: body)
        } catch let error as ActivityError {
            throw error
        } catch {
            throw logAndMap("announceActivity", error)
        }
    }

    public func submitHostFeedback(activityID: String, feedback: ActivityHostFeedback) async throws {
        do {
            let body = try JSONEncoder().encode(ActivityHostFeedbackRequestDTO(feedback: feedback.rawValue))
            try await apiClient.post(ActivityAPIPath.feedback(id: activityID), body: body)
        } catch {
            throw logAndMap("submitHostFeedback", error)
        }
    }

    private func logAndMap(_ operation: String, _ error: Error) -> ActivityError {
        if let activityError = error as? ActivityError {
            logger.error("\(operation, privacy: .public) failed: \(activityError.localizedDescription ?? "", privacy: .public)")
            return activityError
        }
        let mapped = ActivityError.underlying(mapToAppError(error))
        logger.error("\(operation, privacy: .public) failed: \(mapped.localizedDescription ?? "", privacy: .public)")
        return mapped
    }

    private func mapToAppError(_ error: Error) -> AppError {
        if let activityError = error as? ActivityError,
           case let .underlying(appError) = activityError {
            return appError
        }
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(message: error.localizedDescription)
    }
}
