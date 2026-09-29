//
//  ActivityCredentialExpandedView.swift
//  坐标系
//
//  活动旅程页：登机牌 + 阶段操作 + 进度时间线（原凭证展开入口）。
//

import SwiftUI
import CoordinateDomain
import CoordinateModels

struct ActivityCredentialExpandedView: View {
    let activityID: Activity.ID

    @Environment(AppModel.self) private var app
    @Environment(ActivitiesModel.self) private var activities
    @Environment(WalletPassStore.self) private var passStore
    @Environment(RefundFlowService.self) private var refunds
    @Environment(CommunityModel.self) private var community
    @Environment(\.tabNavigationStateRef) private var navigation
    @Environment(\.dismiss) private var dismiss

    @State private var activityContactRoute: PeerContactRoute?

    @State private var showAddToWallet = false
    @State private var showRecapCompose = false
    @State private var showActivityDetail = false
    @State private var showNavigationPicker = false
    @State private var showMementoShareSheet = false
    @State private var mementoShareItems: [Any] = []
    @State private var showReportSheet = false
    @State private var showFeedbackSheet = false
    @State private var calendarMessage: String?
    @State private var reportMessage: String?
    @State private var cancelRefundActivityID: Activity.ID?
    @State private var cancelUnpaidActivityID: Activity.ID?
    @State private var cancelAndRefundOrder: ActivityOrder?
    @State private var presentedRefundRequestID: UUID?
    @State private var showCancelHostAlert = false
    @State private var actionIssueMessage: String?
    @State private var cancelFeedbackMessage: String?
    @State private var checkInMessage: String?

    private var activity: Activity? {
        activities.activity(id: activityID)
    }

    private var relatedPass: PassRecord? {
        guard let activity else { return nil }
        return passStore.resolvedActivityPass(for: activity)
    }

    private var canShareMemento: Bool {
        guard let activity else { return false }
        let participates = activities.isJoined(activity.id) || isHost
        return ActivityJourneyCredentialPresentation.canShareMemento(
            voided: relatedPass?.voided == true,
            participatesInJourney: participates
        )
    }

    private var isHost: Bool {
        activity.map(activities.isHost) ?? false
    }

    var body: some View {
        Group {
            if let activity {
                journeyContent(activity)
            } else {
                ContentUnavailableView(
                    "活动不可用",
                    systemImage: "ticket",
                    description: Text("这场活动的旅程已无法加载。")
                )
            }
        }
        .navigationTitle(ActivityJourneyCopy.pageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if canShareMemento, let activity {
                    Button {
                        presentMementoShare(for: activity)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel(ActivityJourneyCopy.shareMementoTicket)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if activity != nil {
                    Menu {
                        if let activity {
                            credentialMoreMenu(for: activity)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("更多")
                }
            }
        }
        .sheet(isPresented: $showMementoShareSheet) {
            PlatformShareSheet(items: mementoShareItems)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showReportSheet) {
            if let activity {
                ActivityReportSheet(activity: activity, onSubmit: submitReport)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .alert(
            ActivityDetailCopy.reportReceivedTitle,
            isPresented: Binding(
                get: { reportMessage != nil },
                set: { if !$0 { reportMessage = nil } }
            )
        ) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(reportMessage ?? "")
        }
        .alert(
            ActivityJourneyCopy.alarmReminder,
            isPresented: Binding(
                get: { calendarMessage != nil },
                set: { if !$0 { calendarMessage = nil } }
            )
        ) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(calendarMessage ?? "")
        }
        .sheet(isPresented: $showFeedbackSheet) {
            if let activity {
                ActivityFeedbackSheet(
                    activity: activity,
                    onSubmit: { tag in
                        activities.submitActivityFeedback(activityID, highlight: tag)
                        activities.flashLight(ActivityFeedbackCopy.feedbackThanks)
                    },
                    onSkip: {
                        activities.skipActivityFeedback(activityID)
                    }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .alert(
            ActivityJourneyCopy.onSiteCheckIn,
            isPresented: Binding(
                get: { checkInMessage != nil },
                set: { if !$0 { checkInMessage = nil } }
            )
        ) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(checkInMessage ?? "")
        }
        .sheet(isPresented: $showAddToWallet) {
            addToWalletSheet
        }
        .sheet(isPresented: $showRecapCompose) {
            CommunityComposeSheet()
                .toolbarVisibility(.hidden, for: .tabBar)
                .platformSheet(.form)
        }
        .navigationDestination(isPresented: $showActivityDetail) {
            ActivityDetailView(activityID: activityID)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .alert(
            ActivityDetailCopy.cancelWithRefundTitle,
            isPresented: Binding(
                get: { cancelRefundActivityID != nil },
                set: { if !$0 { cancelRefundActivityID = nil } }
            )
        ) {
            Button("暂不取消", role: .cancel) {
                cancelRefundActivityID = nil
            }
            Button(ActivityDetailCopy.cancelOnly) {
                if let id = cancelRefundActivityID,
                   app.cancelActivityRegistration(id, refundIfPaid: false) {
                    cancelFeedbackMessage = ActivityFeedbackCopy.unjoined
                }
                cancelRefundActivityID = nil
            }
            Button(ActivityDetailCopy.cancelWithRefundConfirm, role: .destructive) {
                if let id = cancelRefundActivityID,
                   let order = ActivityPaymentStore.paidOrder(for: id) {
                    cancelAndRefundOrder = order
                }
                cancelRefundActivityID = nil
            }
        } message: {
            Text(ActivityDetailCopy.cancelWithRefundMessage)
        }
        .alert(
            ActivityDetailCopy.cancelUnpaidTitle,
            isPresented: Binding(
                get: { cancelUnpaidActivityID != nil },
                set: { if !$0 { cancelUnpaidActivityID = nil } }
            )
        ) {
            Button(ActivityDetailCopy.cancelUnpaidKeep, role: .cancel) {
                cancelUnpaidActivityID = nil
            }
            Button(ActivityDetailCopy.cancelUnpaidConfirm, role: .destructive) {
                if let id = cancelUnpaidActivityID,
                   app.cancelActivityRegistration(id) {
                    cancelFeedbackMessage = ActivityFeedbackCopy.unjoined
                }
                cancelUnpaidActivityID = nil
            }
        } message: {
            Text(ActivityDetailCopy.cancelUnpaidMessage)
        }
        .sheet(item: $cancelAndRefundOrder) { order in
            let activity = activities.activity(id: order.activityID)
            let notes = activity.map { ActivityDetailBlueprint.make(for: $0).refundNotes } ?? []
            RefundRequestSheet.activityOrder(order, activity: activity, refundNotes: notes) { reason, detail, _ in
                submitCancelAndRefund(order: order, reason: reason, detail: detail)
            }
        }
        .sheet(isPresented: Binding(
            get: { presentedRefundRequestID != nil },
            set: { if !$0 { presentedRefundRequestID = nil } }
        )) {
            if let requestID = presentedRefundRequestID {
                RefundStatusSheet(requestID: requestID)
            }
        }
        .alert(
            ActivityDetailCopy.hostManageCancelAlertTitle,
            isPresented: $showCancelHostAlert
        ) {
            Button(ActivityDetailCopy.hostManageCancelActivity, role: .destructive) {
                app.cancelHostedActivity(activityID)
                dismiss()
            }
            Button("保留活动", role: .cancel) {}
        } message: {
            Text(
                ActivityDetailCopy.hostManageCancelAlertMessage(
                    title: activity?.title ?? "该活动"
                )
            )
        }
        .alert("无法退款", isPresented: Binding(
            get: { actionIssueMessage != nil },
            set: { if !$0 { actionIssueMessage = nil } }
        )) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(actionIssueMessage ?? "")
        }
        .platformFeedbackAlert($cancelFeedbackMessage)
        .peerContactDestination(route: $activityContactRoute)
    }

    private func openActivityGroupChatInStack(for activity: Activity) {
        activities.markActivityGroupOpened(activity.id)
        guard let route = app.prepareActivityGroupChatRoute(for: activity) else { return }
        if let navigation {
            navigation.path.append(route)
        } else {
            activityContactRoute = .chat(route)
        }
    }

    private func greetCoParticipant(_ name: String, activity: Activity) {
        let context: ConversationChatContext = name == activity.hostName
            ? .activityHost(activityID: activity.id)
            : .activityMember(activityID: activity.id)
        activityContactRoute = app.openPeerContact(with: name, context: context)
    }

    private func consumePendingJourneyFollowUp(for activity: Activity) {
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

    private func journeySyncIdentity(
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
    private func journeyContent(_ activity: Activity) -> some View {
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
            onUtilityAction: { action in
                handleUtilityAction(action, activity: activity)
            },
            onPrimaryAction: { action in
                handlePrimaryAction(action, activity: activity)
            },
            onGreetParticipant: { name in
                greetCoParticipant(name, activity: activity)
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

    private var addToWalletSheet: some View {
        NavigationStack {
            Form {
                if let pass = relatedPass, !pass.voided {
                    Section {
                        WalletPassAddToWalletControl(pass: pass)
                    } footer: {
                        Text(WalletPassKitCopy.addFooter)
                    }
                } else {
                    Section {
                        ContentUnavailableView(
                            "暂无可加入的通行证",
                            systemImage: "wallet.bifold",
                            description: Text(WalletPassKitCopy.addFooter)
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("加入 Apple Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.hidden, for: .tabBar)
            .platformSheetConfirmationToolbar("完成") {
                showAddToWallet = false
            }
        }
        .platformSheet(.confirm)
    }

    private func barcodeMessage(for activity: Activity, voided: Bool) -> String {
        if let pass = passStore.resolvedActivityPass(for: activity, voided: voided) {
            let message = pass.barcodeMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            if !message.isEmpty { return message }
        }
        return "coordinate:activity:\(activity.id.uuidString)"
    }

    private func handleUtilityAction(_ action: ActivityJourneyUtilityAction, activity: Activity) {
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
        case .toggleAlarmReminder:
            guard relatedPass?.voided != true else { return }
            Task { await toggleCalendar(for: activity) }
        }
    }

    private func handlePrimaryAction(_ action: ActivityJourneyPrimaryAction, activity: Activity) {
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

    private func prepareRecapCompose(for activity: Activity) {
        community.pendingRelatedActivityTitle = activity.title
        community.pendingRelatedActivityID = activity.id
        community.pendingComposeBody = "「\(activity.title)」复盘"
        showRecapCompose = true
    }

    private func toggleCalendar(for activity: Activity) async {
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

    private var shouldOfferReissue: Bool {
        guard let activity, relatedPass == nil || relatedPass?.voided == true else { return false }
        return activities.isJoined(activity.id) || isHost
    }

    @ViewBuilder
    private func credentialMoreMenu(for activity: Activity) -> some View {
        if relatedPass?.voided == false {
            Button {
                showAddToWallet = true
            } label: {
                Label(ActivityJourneyCopy.addToWallet, systemImage: "wallet.bifold")
            }
        }

        Button {
            presentMementoShare(for: activity)
        } label: {
            Label(ActivityJourneyCopy.shareMementoTicket, systemImage: "photo.on.rectangle.angled")
        }

        Button {
            mementoShareItems = [shareText(for: activity)]
            showMementoShareSheet = true
        } label: {
            Label(ActivityCardStatus.shareActivity, systemImage: "text.quote")
        }

        if isHost {
            Button(ActivityDetailCopy.hostManageCancelActivity, systemImage: "xmark.circle", role: .destructive) {
                showCancelHostAlert = true
            }
        } else if activities.isJoined(activity.id) {
            if !activity.isLifecycleEnded {
                Button(ActivityDetailCopy.cancelRegistration, systemImage: "xmark.circle", role: .destructive) {
                    requestCancelRegistration(activity)
                }
            }
        }

        if shouldOfferReissue {
            Button(ActivityDetailCopy.credentialReissueAction, systemImage: "ticket") {
                reissue(activity)
            }
        }

        Divider()

        Button(ActivityDetailCopy.reportAction, systemImage: "exclamationmark.bubble", role: .destructive) {
            showReportSheet = true
        }
    }

    private func requestCancelRegistration(_ activity: Activity) {
        if ActivityPaymentStore.hasPaid(for: activity.id) {
            cancelRefundActivityID = activity.id
        } else {
            cancelUnpaidActivityID = activity.id
        }
    }

    @discardableResult
    private func submitCancelAndRefund(order: ActivityOrder, reason: String, detail: String) -> Bool {
        let activity = activities.activity(id: order.activityID)
        let notes = activity.map { ActivityDetailBlueprint.make(for: $0).refundNotes } ?? []
        let result = refunds.submitActivityRefund(
            order: order,
            activity: activity,
            refundNotes: notes,
            reason: reason,
            detail: detail,
            cancelRegistration: true,
            onCancelRegistration: { id in
                app.cancelActivityRegistration(id, refundIfPaid: false)
            }
        )
        switch result {
        case .success(let record):
            presentedRefundRequestID = record.id
            return true
        case .failure(let error):
            actionIssueMessage = error.localizedDescription
            return false
        }
    }

    private func reissue(_ activity: Activity) {
        if let order = ActivityPaymentStore.paidOrder(for: activity.id) {
            _ = passStore.issueActivityTicket(order: order, activity: activity)
        } else {
            _ = passStore.issueActivityAttendanceTicket(for: activity)
        }
    }

    private func presentMementoShare(for activity: Activity) {
        let isVoided = relatedPass?.voided == true
        let participates = activities.isJoined(activity.id) || isHost
        let progress = activities.participationRecord(for: activity.id)
        let phase = ActivityJourneyPresentation.phase(
            for: activity,
            progress: progress,
            participatesInJourney: participates
        )
        let model = ActivityJourneyCredentialPresentation.shareModel(
            for: activity,
            phase: phase,
            voided: isVoided,
            userID: app.user.id,
            participantName: app.user.name,
            participantUIDDisplay: app.user.publicUIDDisplay,
            barcodeMessage: barcodeMessage(for: activity, voided: isVoided)
        )
        let caption = ActivityJourneyCredentialPresentation.shareCaption(for: activity)
        var items: [Any] = [caption]
        if let image = ActivityCredentialShareRenderer.renderMementoCard(
            model: model,
            shareCaption: caption
        ) {
            items.insert(image, at: 0)
        }
        mementoShareItems = items
        showMementoShareSheet = true
    }

    private func shareText(for activity: Activity) -> String {
        "\(activity.title)\n\(Formatters.activityEventTime(from: activity.date))\n\(activity.location)"
    }

    private func submitReport(reason: String, detail: String, evidenceCount: Int) {
        guard let activity else { return }
        var parts = [reason, detail]
        if evidenceCount > 0 {
            parts.append("附件 \(evidenceCount) 张")
        }
        app.addModerationTicket(
            postID: activity.id,
            title: activity.title,
            reason: parts.joined(separator: " · "),
            targetKind: .activity
        )
        reportMessage = ActivityDetailCopy.reportReceivedMessage
    }
}
