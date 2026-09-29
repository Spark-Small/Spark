//
//  ActivityDetailView.swift
//  坐标系
//

import SwiftUI
import CoordinateModels

/// 活动详情：导向「参加」
struct ActivityDetailView: View {
    let activityID: Activity.ID

    @Environment(ActivitiesModel.self) var model
    @Environment(AppModel.self) var app
    @Environment(BuddiesModel.self) var buddies
    @Environment(\.tabNavigationStateRef) var navigation
    @Environment(WalletPassStore.self) var passStore
    @Environment(RefundFlowService.self) var refunds
    @Environment(\.dismiss) var dismiss
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    @State var showHostProfile = false
    @State var showPeopleSheet = false
    @State var showJoinConfirm = false
    @State var joinConfirmWaitlistPromotion = false
    @State var showContentEditor = false
    @State var showOrders = false
    @State var showShareSheet = false
    @State var showReportSheet = false
    @State var contentRevision = 0
    @State var commentsRevision = 0
    @State var ordersRevision = 0
    @State var reportMessage: String?
    @State var joinIssueMessage: String?
    @State var cancelFeedbackMessage: String?
    @State var cancelRefundActivityID: Activity.ID?
    @State var cancelUnpaidActivityID: Activity.ID?
    /// 取消参加并走退款申请表单时暂存的已支付订单
    @State var cancelAndRefundOrder: ActivityOrder?
    @State var presentedRefundRequestID: UUID?
    /// 评论 / 相关轨等次要内容：转场首帧后再挂，减轻 Zoom 合成负载
    @State var revealsSecondaryContent = false
    @State var showCommentsSheet = false
    @State var activityContactRoute: PeerContactRoute?
    @State var showDetailInspector = false
    @State var expandedDetailSections: Set<ActivityDetailSectionID> = []
    @State var showRecapCompose = false
    @State var showFeedbackSheet = false
    @State var favoriteFeedbackPulse = 0
    @State private var showJourneyAfterJoin = false

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(CommunityModel.self) var community

    init(activityID: Activity.ID) {
        self.activityID = activityID
    }

    init(activity: Activity) {
        self.activityID = activity.id
    }

    var activity: Activity? { model.activity(id: activityID) }
    var isHost: Bool { activity.map(model.isHost) ?? false }

    var body: some View {
        Group {
            if let live = activity {
                detailContent(live)
            } else {
                ContentUnavailableView(ActivityDetailCopy.missingActivity, systemImage: "calendar")
                    .onAppear(perform: dismiss.callAsFunction)
            }
        }
        .sheet(isPresented: joinSuccessPresented) {
            joinSuccessSheet
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: publishSuccessPresented) {
            publishSuccessSheet
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .navigationDestination(isPresented: $showJourneyAfterJoin) {
            ActivityCredentialExpandedView(activityID: activityID)
        }
        .sheet(isPresented: $showShareSheet) {
            if let activity {
                PlatformShareSheet(items: [shareText(for: activity)])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            if let activity {
                ActivityReportSheet(activity: activity, onSubmit: submitReport)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .sheet(isPresented: $showHostProfile) {
            if let name = activity?.hostName {
                CommunityAuthorFallbackSheet(name: name)
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
            ActivityDetailCopy.joinFailedFullAfterPayTitle,
            isPresented: Binding(
                get: { joinIssueMessage != nil },
                set: { if !$0 { joinIssueMessage = nil } }
            )
        ) {
            Button(ActivityCardStatus.joinWaitlist) {
                _ = model.toggleWaitlist(activityID)
                joinIssueMessage = nil
            }
            Button("好的", role: .cancel) {
                joinIssueMessage = nil
            }
        } message: {
            Text(joinIssueMessage ?? "")
        }
        .platformFeedbackAlert($cancelFeedbackMessage)
        .platformLightFeedback(
            Binding(
                get: { model.lightFeedbackMessage },
                set: { model.lightFeedbackMessage = $0 }
            )
        )
        .platformFeedbackAlert(
            Binding(
                get: { model.toastMessage },
                set: { model.toastMessage = $0 }
            )
        )
        .sheet(isPresented: $showRecapCompose) {
            CommunityComposeSheet()
                .toolbarVisibility(.hidden, for: .tabBar)
                .platformSheet(.form)
        }
        .sheet(isPresented: $showFeedbackSheet) {
            if let activity {
                ActivityFeedbackSheet(
                    activity: activity,
                    onSubmit: { tag in
                        model.submitActivityFeedback(activity.id, highlight: tag)
                        model.flashLight(ActivityFeedbackCopy.feedbackThanks)
                        showFeedbackSheet = false
                    },
                    onSkip: {
                        model.skipActivityFeedback(activity.id)
                        showFeedbackSheet = false
                    }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
    }


    // MARK: - Success sheets

    private var joinSuccessPresented: Binding<Bool> {
        Binding(
            get: { model.joinSuccessActivityID == activityID },
            set: { if !$0 { model.dismissJoinSuccess() } }
        )
    }

    private var publishSuccessPresented: Binding<Bool> {
        Binding(
            get: { model.publishSuccessActivityID == activityID },
            set: { if !$0 { model.dismissPublishSuccess() } }
        )
    }

    @ViewBuilder
    private var joinSuccessSheet: some View {
        if let live = model.activity(id: activityID) {
            ActivityJoinSuccessSheet(
                activity: live,
                context: .joined,
                onOpenJourney: {
                    model.dismissJoinSuccess()
                    showJourneyAfterJoin = true
                }
            )
        }
    }

    @ViewBuilder
    private var publishSuccessSheet: some View {
        if let live = model.activity(id: activityID) {
            ActivityJoinSuccessSheet(
                activity: live,
                context: .published,
                onOpenGroup: { openGroupChat(for: live) }
            )
        }
    }
}

// MARK: - iPad inspector

struct ActivityDetailSideInspector: View {
    let activity: Activity
    let related: [Activity]
    var onOpenPeople: () -> Void

    var body: some View {
        List {
            Section {
                LabeledContent("时间", value: Formatters.activityEventTime(from: activity.date))
                LabeledContent("地点", value: activity.location)
                LabeledContent("名额") {
                    Text(ActivityCardStatus.spotsText(for: activity))
                }
                Button {
                    onOpenPeople()
                } label: {
                    Label("查看报名伙伴", systemImage: "person.2")
                }
            } header: {
                Text("活动摘要")
            }

            if !related.isEmpty {
                Section {
                    ForEach(related.prefix(6)) { item in
                        LabeledContent(item.title) {
                            Text(Formatters.activityEventTime(from: item.date))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text(ActivityDetailCopy.relatedTitle)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

#Preview("户外") {
    let app = AppModel.preview
    return NavigationStack {
        ActivityDetailView(
            activity: SampleData.activities.first { $0.category == .outdoorSports }!
        )
        .environment(app)
        .environment(app.activities)
        .environment(app.messages)
    }
}
