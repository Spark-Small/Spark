// Module: SparkActivity — Activity invitation detail (signup, group chat, share).

import SparkDesignSystem
import SwiftUI

public struct ActivityDetailView: View {
    @Environment(ActivityCreateTemplateStore.self) var createTemplateStore
    @Environment(ActivityFavoriteStore.self) var favoriteStore
    @State var viewModel: ActivityDetailViewModel
    @State var showEditActivity = false
    @State var showReportSheet = false
    @State var showCancelActivityConfirm = false
    @State var showCancelAttendanceConfirm = false
    @State var showCalendarConfirm = false
    @State var showHostApproval = false
    @State var selectedReportReason: ActivityReportReason = .safety
    @State var blockHostOnReport = true
    @State var showHostAgainCreate = false
    @State var showAnnounceSheet = false
    @State var announceMessage = ""
    @State var meetupMapRoute: ActivityMeetupMapRoute?
    @State var templateFavoriteFeedback: String?

    let coordinator: ActivityCoordinator
    let tabChrome: ActivityTabChrome?
    let isActivityTabSelected: Bool
    let isAuthenticated: Bool
    let onSignInRequired: (() -> Void)?
    let onOpenGroupChat: ((ActivityDetail) async -> Void)?
    let onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)?
    let onActivityRescheduled: ((ActivityDetail) async -> Void)?
    let onCommunityRecap: ((ActivityDetail) -> Void)?
    let fetchBuddyRecommendation: ((String) async -> (listingID: String, title: String, subtitle: String)?)?
    let onOpenBuddyListing: ((String) -> Void)?
    let inviteCandidates: () -> [ActivityInviteCandidate]

    public init(
        activityID: String,
        coordinator: ActivityCoordinator,
        context: ActivityDetailContext = .inbox,
        tabChrome: ActivityTabChrome? = nil,
        isActivityTabSelected: Bool = true,
        isAuthenticated: Bool = true,
        onSignInRequired: (() -> Void)? = nil,
        inviteCandidates: @escaping () -> [ActivityInviteCandidate] = { [] },
        onRSVPCompleted: ((ActivityDetail) async -> Void)? = nil,
        onOpenGroupChat: ((ActivityDetail) async -> Void)? = nil,
        onActivityUpdated: ((ActivityDetail) async -> Void)? = nil,
        onHostBlocked: (() async -> Void)? = nil,
        onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)? = nil,
        onActivityRescheduled: ((ActivityDetail) async -> Void)? = nil,
        onCommunityRecap: ((ActivityDetail) -> Void)? = nil,
        fetchBuddyRecommendation: ((String) async -> (listingID: String, title: String, subtitle: String)?)? = nil,
        onOpenBuddyListing: ((String) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.tabChrome = tabChrome
        self.isActivityTabSelected = isActivityTabSelected
        self.isAuthenticated = isAuthenticated
        self.onSignInRequired = onSignInRequired
        _viewModel = State(
            initialValue: coordinator.makeDetailViewModel(
                activityID: activityID,
                context: context,
                onRSVPCompleted: onRSVPCompleted,
                onActivityUpdated: onActivityUpdated,
                onHostBlocked: onHostBlocked
            )
        )
        self.onOpenGroupChat = onOpenGroupChat
        self.onHostAnnouncePosted = onHostAnnouncePosted
        self.onActivityRescheduled = onActivityRescheduled
        self.onCommunityRecap = onCommunityRecap
        self.fetchBuddyRecommendation = fetchBuddyRecommendation
        self.onOpenBuddyListing = onOpenBuddyListing
        self.inviteCandidates = inviteCandidates
    }

    public init(
        viewModel: ActivityDetailViewModel,
        coordinator: ActivityCoordinator,
        tabChrome: ActivityTabChrome? = nil,
        isActivityTabSelected: Bool = true,
        isAuthenticated: Bool = true,
        onSignInRequired: (() -> Void)? = nil,
        inviteCandidates: @escaping () -> [ActivityInviteCandidate] = { [] },
        onOpenGroupChat: ((ActivityDetail) async -> Void)? = nil,
        onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)? = nil,
        onActivityRescheduled: ((ActivityDetail) async -> Void)? = nil,
        onCommunityRecap: ((ActivityDetail) -> Void)? = nil,
        fetchBuddyRecommendation: ((String) async -> (listingID: String, title: String, subtitle: String)?)? = nil,
        onOpenBuddyListing: ((String) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        self.tabChrome = tabChrome
        self.isActivityTabSelected = isActivityTabSelected
        self.isAuthenticated = isAuthenticated
        self.onSignInRequired = onSignInRequired
        _viewModel = State(initialValue: viewModel)
        self.onOpenGroupChat = onOpenGroupChat
        self.onHostAnnouncePosted = onHostAnnouncePosted
        self.onActivityRescheduled = onActivityRescheduled
        self.onCommunityRecap = onCommunityRecap
        self.fetchBuddyRecommendation = fetchBuddyRecommendation
        self.onOpenBuddyListing = onOpenBuddyListing
        self.inviteCandidates = inviteCandidates
    }

    public var body: some View {
        withDetailAlertsAndDialogs(detailNavigationAndSheets)
        .onAppear {
            refreshTabAccessory()
        }
        .onDisappear {
            tabChrome?.clearDetailAccessory()
            tabChrome?.reconcile()
        }
        .onChange(of: viewModel.loadState) { _, _ in
            refreshTabAccessory()
        }
        .onChange(of: viewModel.isUpdatingRSVP) { _, _ in
            refreshTabAccessory()
        }
        .onChange(of: viewModel.activity?.rsvpStatus) { _, _ in
            refreshTabAccessory()
        }
        .onChange(of: isAuthenticated) { _, _ in
            refreshTabAccessory()
        }
        .onChange(of: isActivityTabSelected) { _, _ in
            refreshTabAccessory()
        }
        .task {
            if viewModel.loadState == .idle {
                await viewModel.load()
            }
        }
    }

    private var detailNavigationAndSheets: some View {
        detailStateRoot
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $meetupMapRoute) { route in
            ActivityMeetupMapView(route: route)
        }
        .navigationDestination(isPresented: $showHostApproval) {
            if let activity = viewModel.activity {
                ActivityHostApprovalView(viewModel: viewModel, activity: activity)
            }
        }
        .toolbar {
            if let activity = viewModel.activity {
                ToolbarItem(placement: .topBarTrailing) {
                    activityDetailToolbarMenu(activity: activity)
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
                            initialDraft: CreateActivityDraft(hostAgainFrom: activity),
                            templateStore: createTemplateStore
                        ),
                        onCreated: { detail in
                            viewModel.applyUpdatedDetail(detail)
                        },
                        onProvisionGroupChat: nil
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var detailStateRoot: some View {
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
                    inviteCandidates: inviteCandidates(),
                    isAuthenticated: isAuthenticated,
                    onSignInRequired: onSignInRequired,
                    onOpenGroupChat: onOpenGroupChat,
                    onCommunityRecap: onCommunityRecap,
                    fetchBuddyRecommendation: fetchBuddyRecommendation,
                    onOpenBuddyListing: onOpenBuddyListing,
                    onRequestAddToCalendar: { showCalendarConfirm = true },
                    onReportTapped: activity.rsvpStatus != .host ? { showReportSheet = true } : nil,
                    tabAccessoryBottomInset: detailBottomScrollInset,
                    meetupMapRoute: $meetupMapRoute,
                    showHostAgainCreate: $showHostAgainCreate
                )
                .modifier(DetailRSVPFallbackModifier(
                    isVisible: showsDetailRSVPFallback,
                    forceInline: tabChrome == nil,
                    kind: detailRSVPFallbackKind,
                    isLoading: viewModel.isUpdatingRSVP,
                    onSignIn: { onSignInRequired?() },
                    onSubmitGoing: {
                        Task { await viewModel.submitRSVP(.going) }
                    }
                ))
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
}

#Preview {
    NavigationStack {
        ActivityDetailView(
            activityID: "act_3",
            coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository())
        )
        .environment(ActivityFavoriteStore())
    }
}

#Preview("External entry") {
    NavigationStack {
        ActivityDetailView(
            activityID: "act_2",
            coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository()),
            context: .externalEntry
        )
        .environment(ActivityFavoriteStore())
    }
}
