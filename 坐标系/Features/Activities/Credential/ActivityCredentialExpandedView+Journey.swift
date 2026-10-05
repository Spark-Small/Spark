//
//  ActivityCredentialExpandedView+Journey.swift
//  坐标系
//
//  活动行程内容栈、商务条与赴约动作。
//

import SwiftUI
import CoordinateDomain
import CoordinateModels

extension ActivityCredentialExpandedView {

    func openActivityGroupChatInStack(for activity: Activity) {
        activities.markActivityGroupOpened(activity.id)
        guard let route = app.prepareActivityGroupChatRoute(for: activity) else { return }
        if let navigation {
            navigation.path.append(route)
        } else {
            activityContactRoute = .chat(route)
        }
    }

    func greetCoParticipant(_ name: String, activity: Activity) {
        let context: ConversationChatContext = name == activity.hostName
            ? .activityHost(activityID: activity.id)
            : .activityMember(activityID: activity.id)
        activityContactRoute = app.openPeerContact(with: name, context: context)
    }

    func consumePendingJourneyFollowUp(for activity: Activity) {
        switch app.pendingActivityJourneyFollowUp {
        case .none:
            break
        case .journeyFeedback:
            app.pendingActivityJourneyFollowUp = .none
            showFeedbackSheet = true
        case .journeyRecap:
            app.pendingActivityJourneyFollowUp = .none
            prepareRecapCompose(for: activity)
        case .openJourney:
            app.pendingActivityJourneyFollowUp = .none
        }
    }

    func journeySyncIdentity(
        for activity: Activity,
        progress: ActivityParticipationProgress?
    ) -> String {
        let scheduled = ActivityCalendar.isScheduled(activityID: activity.id)
        return [
            activity.id.uuidString,
            String(activities.calendarSyncRevision),
            scheduled ? "cal" : "no-cal",
            progress.map {
                "\($0.openedActivityGroup)-\($0.feedbackSubmitted)-\($0.recapPublished)-\($0.markedArrived)"
            } ?? "none"
        ].joined(separator: "|")
    }

    @ViewBuilder
    func journeyContent(_ activity: Activity) -> some View {
        let isVoided = relatedPass?.voided == true
        let participates = activities.isJoined(activity.id) || isHost
        let progress = activities.participationRecord(for: activity.id)
        let phase = ActivityJourneyPresentation.phase(
            for: activity,
            progress: progress,
            participatesInJourney: participates
        )

        let coParticipants = activity.displayParticipants.filter { $0 != app.user.name }
        let scheduledOnCalendar = ActivityCalendar.isScheduled(activityID: activity.id)

        ActivityJourneyStack(
            activity: activity,
            phase: phase,
            progress: progress,
            voided: isVoided,
            isOnCalendar: scheduledOnCalendar,
            userID: app.user.id,
            participantName: app.user.name,
            participantUIDDisplay: app.user.publicUIDDisplay,
            barcodeMessage: barcodeMessage(for: activity, voided: isVoided),
            coParticipantNames: coParticipants,
            commerce: ActivityJourneyCommerceModel.resolve(
                activityID: activity.id,
                refunds: refunds
            ),
            onUtilityAction: { action in
                handleUtilityAction(action, activity: activity)
            },
            onPrimaryAction: { action in
                handlePrimaryAction(action, activity: activity)
            },
            onGreetParticipant: { name in
                greetCoParticipant(name, activity: activity)
            },
            onCommerceAction: { action in
                handleCommerceAction(action)
            }
        )
        .id(journeySyncIdentity(for: activity, progress: progress))
        .onAppear {
            activities.ensureParticipationProgress(for: activity.id)
            consumePendingJourneyFollowUp(for: activity)
        }
        .activityMapNavigationSheet(
            activity: Binding(
                get: { showNavigationPicker ? activity : nil },
                set: { showNavigationPicker = $0 != nil }
            )
        )
    }

    func handleCommerceAction(_ action: ActivityJourneyCommerceAction) {
        switch action {
        case .resumePayment:
            showJoinConfirm = true
        case .openOrders:
            showOrders = true
        case .openRefund(let requestID):
            presentedRefundRequestID = requestID
        }
    }

    func completeJourneyJoin(for activity: Activity, note: String?) {
        guard app.requireIdentityAccess(source: .activityJoin) else { return }
        if let note, !note.isEmpty {
            _ = app.messages.sendFriendRequest(
                to: activity.hostName,
                message: "\(ActivityDetailCopy.joinNotePrefix)\(note)"
            )
        }
        if !activities.isJoined(activity.id) {
            _ = app.toggleJoinActivity(activity.id)
        }
        _ = passStore.issueActivityAttendanceTicket(for: activity)
    }

    func barcodeMessage(for activity: Activity, voided: Bool) -> String {
        if let pass = passStore.resolvedActivityPass(for: activity, voided: voided) {
            let message = pass.barcodeMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            if !message.isEmpty { return message }
        }
        return "coordinate:activity:\(activity.id.uuidString)"
    }

    func handleUtilityAction(_ action: ActivityJourneyUtilityAction, activity: Activity) {
        switch action {
        case .checkIn:
            guard relatedPass?.voided != true else { return }
            let progress = activities.participationRecord(for: activity.id)
            let phase = ActivityJourneyPresentation.phase(
                for: activity,
                progress: progress,
                participatesInJourney: activities.isJoined(activity.id) || isHost
            )
            if progress?.markedArrived == true {
                return
            }
            if ActivityJourneyPresentation.canCheckIn(
                phase: phase,
                markedArrived: false,
                voided: false
            ) {
                activities.markActivityArrived(activity.id)
                checkInMessage = ActivityJourneyCopy.checkInSuccess
            } else {
                checkInMessage = ActivityJourneyCopy.checkInNotYet
            }
        }
    }

    func handlePrimaryAction(_ action: ActivityJourneyPrimaryAction, activity: Activity) {
        switch action {
        case .openDetail:
            showActivityDetail = true
        case .openGroup:
            openActivityGroupChatInStack(for: activity)
        case .navigate:
            showNavigationPicker = true
        case .shareFeedback:
            showFeedbackSheet = true
        case .writeRecap:
            prepareRecapCompose(for: activity)
        case .toggleAlarmReminder:
            Task { await toggleCalendar(for: activity) }
        }
    }

    func prepareRecapCompose(for activity: Activity) {
        community.pendingRelatedActivityTitle = activity.title
        community.pendingRelatedActivityID = activity.id
        community.pendingComposeBody = "「\(activity.title)」复盘"
        showRecapCompose = true
    }

    func toggleCalendar(for activity: Activity) async {
        switch await ActivityCalendar.toggle(activity, withReminders: true) {
        case .added(let withReminders):
            activities.bumpCalendarSync()
            calendarMessage = ActivityCalendar.successMessage(withReminders: withReminders)
        case .removed:
            activities.bumpCalendarSync()
            calendarMessage = ActivityCalendar.removedMessage
        case .accessDenied:
            calendarMessage = "请在系统设置中允许访问日历。"
        case .failed:
            calendarMessage = "暂时无法更新日历，请稍后再试。"
        }
    }
}
