//
//  ActivityCredentialExpandedView.swift
//  坐标系
//
//  活动旅程页：登机牌 + 阶段操作 + 进度时间线（原凭证展开入口）。
//

import SwiftUI
import CoordinateDomain
import CoordinateModels

@MainActor
struct ActivityCredentialExpandedView: View {
    let activityID: Activity.ID

    // 跨文件 extension（+Journey / +Actions）需 internal，勿用 private。
    @Environment(AppModel.self) var app
    @Environment(ActivitiesModel.self) var activities
    @Environment(WalletPassStore.self) var passStore
    @Environment(RefundFlowService.self) var refunds
    @Environment(CommunityModel.self) var community
    @Environment(\.tabNavigationStateRef) var navigation
    @Environment(\.dismiss) var dismiss

    @State var activityContactRoute: PeerContactRoute?

    @State var showRecapCompose = false
    @State var showActivityDetail = false
    @State var showNavigationPicker = false
    @State var showMementoShareSheet = false
    @State var mementoShareItems: [Any] = []
    @State var showReportSheet = false
    @State var showFeedbackSheet = false
    @State var calendarMessage: String?
    @State var reportMessage: String?
    @State var cancelRefundActivityID: Activity.ID?
    @State var cancelUnpaidActivityID: Activity.ID?
    @State var cancelAndRefundOrder: ActivityOrder?
    @State var presentedRefundRequestID: UUID?
    @State var showCancelHostAlert = false
    @State var actionIssueMessage: String?
    @State var cancelFeedbackMessage: String?
    @State var checkInMessage: String?
    @State var showOrders = false
    @State var showJoinConfirm = false

    var activity: Activity? {
        activities.activity(id: activityID)
    }

    var relatedPass: PassRecord? {
        guard let activity else { return nil }
        return passStore.resolvedActivityPass(for: activity)
    }

    var canShareMemento: Bool {
        guard let activity else { return false }
        let participates = activities.isJoined(activity.id) || isHost
        return ActivityJourneyCredentialPresentation.canShareMemento(
            voided: relatedPass?.voided == true,
            participatesInJourney: participates
        )
    }

    var isHost: Bool {
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
        .sheet(isPresented: $showOrders) {
            ActivityOrdersSheet(
                activityID: activityID,
                onResumePayment: {
                    showOrders = false
                    showJoinConfirm = true
                }
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showJoinConfirm) {
            if let activity {
                ActivityJoinConfirmSheet(
                    activity: activity,
                    conflicts: activities.scheduleConflicts(with: activity)
                ) { note in
                    completeJourneyJoin(for: activity, note: note)
                }
                .toolbarVisibility(.hidden, for: .tabBar)
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
            Button(ActivityDetailCopy.hostManageKeepActivity, role: .cancel) {}
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
}
