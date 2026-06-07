// Module: SparkActivity — Activity invitation detail state.

import Foundation
import Observation
import os
import SparkCore

@MainActor
@Observable
public final class ActivityDetailViewModel {
    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failure(String)
    }

    public let activityID: String
    public let context: ActivityDetailContext
    public private(set) var activity: ActivityDetail?
    public private(set) var shouldPromptInviteFriends = false
    public private(set) var loadState: LoadState = .idle
    public private(set) var isUpdatingRSVP = false
    public private(set) var isPerformingHostAction = false
    public private(set) var rsvpErrorMessage: String?
    public private(set) var hostFeedbackMessage: String?
    public private(set) var calendarFeedbackMessage: String?
    public private(set) var reportFeedbackMessage: String?
    public private(set) var hostOtherActivities: [ActivityItem] = []
    public private(set) var hostOtherActivitiesLoadFailed = false
    public private(set) var feedbackSubmitted = false

    private let fetchDetail: FetchActivityDetailUseCase
    private let updateRSVP: UpdateActivityRSVPUseCase
    private let cancelActivity: CancelActivityUseCase
    private let reportActivity: ReportActivityUseCase
    private let joinWaitlist: JoinActivityWaitlistUseCase
    private let promoteFromWaitlist: PromoteFromWaitlistUseCase
    private let announceActivity: AnnounceActivityUseCase
    private let submitHostFeedbackUseCase: SubmitHostFeedbackUseCase
    private let fetchHostActivities: FetchActivitiesByHostUseCase
    private let blockedHostsStore: BlockedActivityHostsStore
    private let calendarExporter: any ActivityCalendarExporting
    private let onRSVPCompleted: ((ActivityDetail) async -> Void)?
    private let onActivityUpdated: ((ActivityDetail) async -> Void)?
    private let logger = Logger(subsystem: SparkLog.subsystem, category: "ActivityDetail")
    private var loadGeneration = 0

    public init(
        activityID: String,
        repository: any ActivityFeedRepository,
        context: ActivityDetailContext = .inbox,
        blockedHostsStore: BlockedActivityHostsStore = BlockedActivityHostsStore(),
        calendarExporter: (any ActivityCalendarExporting)? = nil,
        onRSVPCompleted: ((ActivityDetail) async -> Void)? = nil,
        onActivityUpdated: ((ActivityDetail) async -> Void)? = nil
    ) {
        self.activityID = activityID
        self.context = context
        self.blockedHostsStore = blockedHostsStore
        fetchDetail = FetchActivityDetailUseCase(repository: repository)
        updateRSVP = UpdateActivityRSVPUseCase(repository: repository)
        cancelActivity = CancelActivityUseCase(repository: repository)
        reportActivity = ReportActivityUseCase(repository: repository)
        joinWaitlist = JoinActivityWaitlistUseCase(repository: repository)
        promoteFromWaitlist = PromoteFromWaitlistUseCase(repository: repository)
        announceActivity = AnnounceActivityUseCase(repository: repository)
        submitHostFeedbackUseCase = SubmitHostFeedbackUseCase(repository: repository)
        fetchHostActivities = FetchActivitiesByHostUseCase(repository: repository)
        self.calendarExporter = calendarExporter ?? ActivityCalendarExportService()
        self.onRSVPCompleted = onRSVPCompleted
        self.onActivityUpdated = onActivityUpdated
    }

    public func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        loadState = .loading
        rsvpErrorMessage = nil
        hostOtherActivitiesLoadFailed = false
        do {
            activity = try await fetchDetail(activityID: activityID)
            guard generation == loadGeneration else { return }
            await loadHostOtherActivities(generation: generation)
            guard generation == loadGeneration else { return }
            loadState = .loaded
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }
            loadState = .failure(error.localizedDescription)
        }
    }

    public func clearInviteFriendsPrompt() {
        shouldPromptInviteFriends = false
    }

    public func notifyInviteCopied() {
        hostFeedbackMessage = String(
            localized: "activity.invite.copied",
            defaultValue: "邀请文案已复制",
            comment: "Copy feedback"
        )
    }

    public func applyUpdatedDetail(_ detail: ActivityDetail) {
        activity = detail
        hostFeedbackMessage = String(
            localized: "activity.host.saved",
            defaultValue: "活动已更新",
            comment: "Host save feedback"
        )
        Task { await onActivityUpdated?(detail) }
    }

    public func submitRSVP(_ status: ActivityRSVPStatus) async {
        guard let activity, activity.canChangeRSVP else { return }
        if status == .going, !activity.canSelectGoing {
            rsvpErrorMessage = ActivityError.activityFull.errorDescription
            return
        }
        isUpdatingRSVP = true
        rsvpErrorMessage = nil
        defer { isUpdatingRSVP = false }
        do {
            let updated = try await updateRSVP(activityID: activityID, status: status)
            self.activity = updated
            if context == .externalEntry || context == .discover, updated.rsvpStatus.hasGroupChatAccess {
                shouldPromptInviteFriends = true
            }
            if updated.rsvpStatus.hasGroupChatAccess {
                switch context {
                case .discover where updated.rsvpStatus == .going || updated.rsvpStatus == .maybe:
                    IntegrationTelemetry.browseToRSVP(activityID: activityID)
                case .externalEntry where updated.rsvpStatus == .going || updated.rsvpStatus == .maybe:
                    IntegrationTelemetry.inviteLinkToRSVP(activityID: activityID)
                default:
                    break
                }
                IntegrationTelemetry.rsvpCompleted(
                    source: context.integrationTelemetrySource,
                    activityID: activityID
                )
                await onRSVPCompleted?(updated)
            }
            await ActivityLocalReminderScheduler.syncReminders(for: updated)
        } catch is CancellationError {
            return
        } catch let error as ActivityError {
            rsvpErrorMessage = error.errorDescription
        } catch {
            rsvpErrorMessage = error.localizedDescription
        }
    }

    public func cancelAttendance() async {
        await submitRSVP(.declined)
    }

    public func cancelActivityAsHost() async {
        isPerformingHostAction = true
        hostFeedbackMessage = nil
        defer { isPerformingHostAction = false }
        do {
            let updated = try await cancelActivity(activityID: activityID)
            activity = updated
            hostFeedbackMessage = String(
                localized: "activity.host.cancelled",
                defaultValue: "活动已取消，报名者将看到已取消状态。",
                comment: "Host cancel feedback"
            )
            await onActivityUpdated?(updated)
        } catch is CancellationError {
            return
        } catch {
            hostFeedbackMessage = error.localizedDescription
        }
    }

    public func submitReport(_ reason: ActivityReportReason, blockHost: Bool) async {
        reportFeedbackMessage = nil
        do {
            let result = try await reportActivity(activityID: activityID, reason: reason)
            if blockHost, let hostID = activity?.hostID {
                await blockedHostsStore.block(hostID: hostID)
            }
            let format = String(
                localized: "activity.report.submitted.withId",
                defaultValue: "已收到举报（编号 %@），我们会尽快处理。",
                comment: "Report feedback with id"
            )
            reportFeedbackMessage = String(format: format, locale: .current, result.reportID)
        } catch is CancellationError {
            return
        } catch {
            reportFeedbackMessage = error.localizedDescription
        }
    }

    public func joinWaitlist() async {
        guard activity?.canJoinWaitlist == true else { return }
        isUpdatingRSVP = true
        rsvpErrorMessage = nil
        defer { isUpdatingRSVP = false }
        do {
            let updated = try await joinWaitlist(activityID: activityID)
            activity = updated
        } catch is CancellationError {
            return
        } catch {
            rsvpErrorMessage = error.localizedDescription
        }
    }

    public func promoteWaitlistedAttendee(_ attendeeID: String) async {
        isPerformingHostAction = true
        hostFeedbackMessage = nil
        defer { isPerformingHostAction = false }
        do {
            let updated = try await promoteFromWaitlist(activityID: activityID, attendeeID: attendeeID)
            activity = updated
            hostFeedbackMessage = String(
                localized: "activity.host.promoted",
                defaultValue: "已将该候补提升为参加。",
                comment: "Promote waitlist"
            )
            await onActivityUpdated?(updated)
        } catch is CancellationError {
            return
        } catch {
            hostFeedbackMessage = error.localizedDescription
        }
    }

    public func announceToAttendees(message: String) async {
        isPerformingHostAction = true
        hostFeedbackMessage = nil
        defer { isPerformingHostAction = false }
        do {
            try await announceActivity(activityID: activityID, message: message)
            hostFeedbackMessage = String(
                localized: "activity.host.announced",
                defaultValue: "通知已发送给报名者。",
                comment: "Announce feedback"
            )
        } catch is CancellationError {
            return
        } catch let error as ActivityError {
            hostFeedbackMessage = error.errorDescription
        } catch {
            hostFeedbackMessage = error.localizedDescription
        }
    }

    public func submitHostFeedback(_ feedback: ActivityHostFeedback) async {
        do {
            try await submitHostFeedbackUseCase(activityID: activityID, feedback: feedback)
            feedbackSubmitted = true
        } catch is CancellationError {
            return
        } catch {
            hostFeedbackMessage = error.localizedDescription
        }
    }

    private func loadHostOtherActivities(generation: Int) async {
        guard let hostID = activity?.hostID else {
            hostOtherActivities = []
            hostOtherActivitiesLoadFailed = false
            return
        }
        do {
            hostOtherActivities = try await fetchHostActivities(hostID: hostID, excludingActivityID: activityID)
            hostOtherActivitiesLoadFailed = false
        } catch {
            guard generation == loadGeneration else { return }
            hostOtherActivities = []
            hostOtherActivitiesLoadFailed = true
            logger.error("loadHostOtherActivities failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    public func addToCalendar() async {
        guard let activity else { return }
        calendarFeedbackMessage = nil
        let result = await calendarExporter.addToCalendar(activity: activity)
        calendarFeedbackMessage = message(for: result)
    }

    private func message(for result: ActivityCalendarExportResult) -> String {
        switch result {
        case .added:
            String(
                localized: "activity.calendar.added",
                defaultValue: "已加入日历",
                comment: "Calendar feedback"
            )
        case .accessDenied:
            String(
                localized: "activity.calendar.denied",
                defaultValue: "请在系统设置中允许访问日历。",
                comment: "Calendar feedback"
            )
        case let .failed(description):
            description
        }
    }
}
