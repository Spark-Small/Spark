// Module: SparkActivity — Activity invitation detail (signup, group chat, share).

import SparkDesignSystem
import SwiftUI

public struct ActivityDetailView: View {
    @State private var viewModel: ActivityDetailViewModel
    @State private var showEditActivity = false
    @State private var showReportSheet = false
    @State private var showCancelActivityConfirm = false
    @State private var selectedReportReason: ActivityReportReason = .safety
    @State private var blockHostOnReport = true
    @State private var showHostAgainCreate = false
    @State private var showAnnounceSheet = false
    @State private var announceMessage = ""

    private let coordinator: ActivityCoordinator
    private let onOpenGroupChat: ((ActivityDetail) async -> Void)?
    private let onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)?
    private let onActivityRescheduled: ((ActivityDetail) async -> Void)?
    private let onCommunityRecap: ((ActivityDetail) -> Void)?

    public init(
        activityID: String,
        coordinator: ActivityCoordinator,
        context: ActivityDetailContext = .inbox,
        onRSVPCompleted: ((ActivityDetail) async -> Void)? = nil,
        onOpenGroupChat: ((ActivityDetail) async -> Void)? = nil,
        onActivityUpdated: ((ActivityDetail) async -> Void)? = nil,
        onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)? = nil,
        onActivityRescheduled: ((ActivityDetail) async -> Void)? = nil,
        onCommunityRecap: ((ActivityDetail) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        _viewModel = State(
            initialValue: coordinator.makeDetailViewModel(
                activityID: activityID,
                context: context,
                onRSVPCompleted: onRSVPCompleted,
                onActivityUpdated: onActivityUpdated
            )
        )
        self.onOpenGroupChat = onOpenGroupChat
        self.onHostAnnouncePosted = onHostAnnouncePosted
        self.onActivityRescheduled = onActivityRescheduled
        self.onCommunityRecap = onCommunityRecap
    }

    public init(
        viewModel: ActivityDetailViewModel,
        coordinator: ActivityCoordinator,
        onOpenGroupChat: ((ActivityDetail) async -> Void)? = nil,
        onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)? = nil,
        onActivityRescheduled: ((ActivityDetail) async -> Void)? = nil,
        onCommunityRecap: ((ActivityDetail) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        _viewModel = State(initialValue: viewModel)
        self.onOpenGroupChat = onOpenGroupChat
        self.onHostAnnouncePosted = onHostAnnouncePosted
        self.onActivityRescheduled = onActivityRescheduled
        self.onCommunityRecap = onCommunityRecap
    }

    public var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sparkLoadingAccessibilityLabel(
                        String(
                            localized: "activity.detail.loading.a11y",
                            defaultValue: "正在加载活动",
                            comment: "Activity detail loading"
                        )
                    )
            case .failure(let message):
                SparkRetryUnavailableView(
                    title: String(
                        localized: "activity.detail.error.title",
                        defaultValue: "无法加载活动",
                        comment: "Activity detail error"
                    ),
                    description: message
                ) {
                    Task { await viewModel.load() }
                }
            case .loaded:
                if let activity = viewModel.activity {
                    ActivityDetailLoadedList(
                        viewModel: viewModel,
                        activity: activity,
                        onOpenGroupChat: onOpenGroupChat,
                        onCommunityRecap: onCommunityRecap,
                        showEditActivity: $showEditActivity,
                        showAnnounceSheet: $showAnnounceSheet,
                        showHostAgainCreate: $showHostAgainCreate,
                        showCancelActivityConfirm: $showCancelActivityConfirm
                    )
                } else {
                    ProgressView()
                        .sparkLoadingAccessibilityLabel(
                            String(
                                localized: "activity.detail.loading.a11y",
                                defaultValue: "正在加载活动",
                                comment: "Activity detail loading"
                            )
                        )
                }
            }
        }
        .navigationTitle(viewModel.activity?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let activity = viewModel.activity {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ShareLink(
                            item: ActivityInviteURL.shareLink(activityID: activity.id),
                            subject: Text(activity.title),
                            message: Text(ActivityInviteURL.inviteCopyText(activity: activity))
                        ) {
                            Label(
                                String(localized: "activity.share.menu", defaultValue: "分享邀请", comment: "Share"),
                                systemImage: "square.and.arrow.up"
                            )
                        }
                        Button {
                            ActivityPasteboard.copy(ActivityInviteURL.inviteCopyText(activity: activity))
                            viewModel.notifyInviteCopied()
                        } label: {
                            Label(
                                String(localized: "activity.copyInvite", defaultValue: "复制邀请文案", comment: "Copy invite"),
                                systemImage: "doc.on.doc"
                            )
                        }
                        if activity.rsvpStatus != .host {
                            Button(role: .destructive) {
                                showReportSheet = true
                            } label: {
                                Label(
                                    String(localized: "activity.report.menu", defaultValue: "举报活动", comment: "Report"),
                                    systemImage: "exclamationmark.bubble"
                                )
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel(
                        String(localized: "activity.detail.more.a11y", defaultValue: "更多操作", comment: "More a11y")
                    )
                }
            }
        }
        .sheet(isPresented: $showEditActivity) {
            if let activity = viewModel.activity {
                NavigationStack {
                    EditActivityView(
                        viewModel: coordinator.makeEditViewModel(activity: activity),
                        onSaved: { updated in
                            let previousStartsAt = viewModel.activity?.startsAt
                            viewModel.applyUpdatedDetail(updated)
                            if let previousStartsAt, previousStartsAt != updated.startsAt {
                                Task { await onActivityRescheduled?(updated) }
                            }
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            reportSheet
        }
        .sheet(isPresented: $showAnnounceSheet) {
            announceSheet
        }
        .sheet(isPresented: $showHostAgainCreate) {
            if let activity = viewModel.activity {
                NavigationStack {
                    CreateActivityView(
                        viewModel: coordinator.makeCreateViewModel(
                            initialDraft: CreateActivityDraft(hostAgainFrom: activity)
                        ),
                        onCreated: { detail in
                            viewModel.applyUpdatedDetail(detail)
                        },
                        onProvisionGroupChat: nil
                    )
                }
            }
        }
        .confirmationDialog(
            String(
                localized: "activity.host.cancel.confirm.title",
                defaultValue: "取消这场活动？",
                comment: "Cancel confirm"
            ),
            isPresented: $showCancelActivityConfirm,
            titleVisibility: .visible
        ) {
            Button(
                String(localized: "activity.host.cancel.confirm.action", defaultValue: "取消活动", comment: "Cancel action"),
                role: .destructive
            ) {
                Task { await viewModel.cancelActivityAsHost() }
            }
            Button(String(localized: "action.cancel", defaultValue: "返回", comment: "Dismiss"), role: .cancel) {}
        } message: {
            Text(
                String(
                    localized: "activity.host.cancel.confirm.message",
                    defaultValue: "报名者会看到活动已取消，群聊仍可查看历史消息。",
                    comment: "Cancel confirm message"
                )
            )
        }
        .task {
            if viewModel.loadState == .idle {
                await viewModel.load()
            }
        }
    }

    private var announceSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        String(
                            localized: "activity.host.announce.placeholder",
                            defaultValue: "通知内容",
                            comment: "Announce placeholder"
                        ),
                        text: $announceMessage,
                        axis: .vertical
                    )
                    .lineLimit(3 ... 6)
                }
            }
            .sparkDismissesKeyboardOnScroll()
            .navigationTitle(
                String(localized: "activity.host.announce.title", defaultValue: "通知报名者", comment: "Announce title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                        showAnnounceSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "activity.host.announce.send", defaultValue: "发送", comment: "Send announce")) {
                        Task {
                            guard let activity = viewModel.activity else { return }
                            await viewModel.announceToAttendees(message: announceMessage)
                            await onHostAnnouncePosted?(activity, announceMessage)
                            showAnnounceSheet = false
                            announceMessage = ""
                        }
                    }
                    .disabled(announceMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var reportSheet: some View {
        NavigationStack {
            Form {
                Picker(
                    String(localized: "activity.report.reason", defaultValue: "举报原因", comment: "Report picker"),
                    selection: $selectedReportReason
                ) {
                    ForEach(ActivityReportReason.allCases) { reason in
                        Text(reason.localizedLabel).tag(reason)
                    }
                }
                if viewModel.activity?.hostID != nil {
                    Toggle(
                        String(
                            localized: "activity.report.blockHost",
                            defaultValue: "同时不再看到该主办的活动",
                            comment: "Block host toggle"
                        ),
                        isOn: $blockHostOnReport
                    )
                }
                if let message = viewModel.reportFeedbackMessage {
                    Section {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sparkDismissesKeyboardOnScroll()
            .navigationTitle(
                String(localized: "activity.report.title", defaultValue: "举报活动", comment: "Report title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                        showReportSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "activity.report.submit", defaultValue: "提交", comment: "Submit report")) {
                        Task {
                            await viewModel.submitReport(selectedReportReason, blockHost: blockHostOnReport)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        ActivityDetailView(
            activityID: "act_3",
            coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository())
        )
    }
}

#Preview("External entry") {
    NavigationStack {
        ActivityDetailView(
            activityID: "act_2",
            coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository()),
            context: .externalEntry
        )
    }
}
