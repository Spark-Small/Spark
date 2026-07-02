// Module: SparkActivity — Activity tab root presentation.

import SparkDesignSystem
import SwiftUI

public struct ActivityRootView: View {
    @Binding var pendingActivityID: String?
    @Binding var pendingActivityDetailContext: ActivityDetailContext?
    @Binding var pendingCreateActivityDraft: CreateActivityDraft?
    @Binding var pendingBrowseJoinActivityID: String?
    @State var viewModel: ActivityViewModel
    @State var navigationPath = NavigationPath()

    let coordinator: ActivityCoordinator
    let onRSVPCompleted: ((ActivityDetail) async -> Void)?
    let onOpenGroupChat: ((ActivityDetail) async -> Void)?
    let onActivityCreated: ((ActivityDetail) async -> Void)?
    let isItemLocked: (Int) -> Bool
    let onLockedItemTap: (() -> Void)?
    let onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)?
    let onActivityRescheduled: ((ActivityDetail) async -> Void)?
    let onCommunityRecap: ((ActivityDetail) -> Void)?
    let fetchBuddyRecommendation: ((String) async -> (listingID: String, title: String, subtitle: String)?)?
    let onOpenBuddyListing: ((String) -> Void)?
    let inviteCandidates: () -> [ActivityInviteCandidate]
    let actionItemsInset: (ActivityListFilter) -> AnyView
    let requestActivityIDs: (ActivityListFilter) -> Set<String>
    let isAuthenticated: Bool
    let onSignInRequired: (() -> Void)?
    let onSignInRequiredForActivity: ((String) -> Void)?
    let onSignInRequiredForBrowseJoin: ((String) -> Void)?
    let onSignInRequiredForCreate: ((CreateActivityDraft) -> Void)?
    let tabChrome: ActivityTabChrome
    let isActivityTabSelected: Bool

    @State var showCreateActivity = false
    @State var showMyActivities = false
    @State var showActivityReminders = false
    @State var showActivityToolbarActions = false
    @State var myActivitiesNavigationPath = NavigationPath()
    @State var selectedHomeSegment: ActivityHomeSegment = .discover
    @State var browseViewModel: ActivityBrowseViewModel?
    @State var activityFavoriteStore = ActivityFavoriteStore()
    @State var activityCreateTemplateStore = ActivityCreateTemplateStore()
    @State var externalEntryActivityID: String?
    @State var discoverJoinSheetItem: ActivityItem?
    @State var hostProfileRoute: ActivityHostProfileRoute?

    let onOpenHostMessages: ((String) -> Void)?

    public init<ActionItems: View>(
        coordinator: ActivityCoordinator,
        inboxViewModel: ActivityViewModel? = nil,
        pendingActivityID: Binding<String?> = .constant(nil),
        pendingActivityDetailContext: Binding<ActivityDetailContext?> = .constant(nil),
        pendingCreateActivityDraft: Binding<CreateActivityDraft?> = .constant(nil),
        pendingBrowseJoinActivityID: Binding<String?> = .constant(nil),
        onRSVPCompleted: ((ActivityDetail) async -> Void)? = nil,
        onOpenGroupChat: ((ActivityDetail) async -> Void)? = nil,
        onActivityCreated: ((ActivityDetail) async -> Void)? = nil,
        isItemLocked: @escaping (Int) -> Bool = { _ in false },
        onLockedItemTap: (() -> Void)? = nil,
        onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)? = nil,
        onActivityRescheduled: ((ActivityDetail) async -> Void)? = nil,
        onCommunityRecap: ((ActivityDetail) -> Void)? = nil,
        fetchBuddyRecommendation: ((String) async -> (listingID: String, title: String, subtitle: String)?)? = nil,
        onOpenBuddyListing: ((String) -> Void)? = nil,
        inviteCandidates: @escaping () -> [ActivityInviteCandidate] = { [] },
        @ViewBuilder actionItemsInset: @escaping (ActivityListFilter) -> ActionItems = { _ in EmptyView() },
        requestActivityIDs: @escaping (ActivityListFilter) -> Set<String> = { _ in [] },
        isAuthenticated: Bool = true,
        onSignInRequired: (() -> Void)? = nil,
        onSignInRequiredForActivity: ((String) -> Void)? = nil,
        onSignInRequiredForBrowseJoin: ((String) -> Void)? = nil,
        onSignInRequiredForCreate: ((CreateActivityDraft) -> Void)? = nil,
        onOpenHostMessages: ((String) -> Void)? = nil,
        tabChrome: ActivityTabChrome = ActivityTabChrome(),
        isActivityTabSelected: Bool = true
    ) {
        self.coordinator = coordinator
        _pendingActivityID = pendingActivityID
        _pendingActivityDetailContext = pendingActivityDetailContext
        _pendingCreateActivityDraft = pendingCreateActivityDraft
        _pendingBrowseJoinActivityID = pendingBrowseJoinActivityID
        _viewModel = State(initialValue: inboxViewModel ?? coordinator.makeInboxViewModel())
        _browseViewModel = State(
            initialValue: coordinator.hasBrowseCatalog ? coordinator.makeBrowseViewModel() : nil
        )
        self.onRSVPCompleted = onRSVPCompleted
        self.onOpenGroupChat = onOpenGroupChat
        self.onActivityCreated = onActivityCreated
        self.isItemLocked = isItemLocked
        self.onLockedItemTap = onLockedItemTap
        self.onHostAnnouncePosted = onHostAnnouncePosted
        self.onActivityRescheduled = onActivityRescheduled
        self.onCommunityRecap = onCommunityRecap
        self.fetchBuddyRecommendation = fetchBuddyRecommendation
        self.onOpenBuddyListing = onOpenBuddyListing
        self.inviteCandidates = inviteCandidates
        self.actionItemsInset = { filter in AnyView(actionItemsInset(filter)) }
        self.requestActivityIDs = requestActivityIDs
        self.isAuthenticated = isAuthenticated
        self.onSignInRequired = onSignInRequired
        self.onSignInRequiredForActivity = onSignInRequiredForActivity
        self.onSignInRequiredForBrowseJoin = onSignInRequiredForBrowseJoin
        self.onSignInRequiredForCreate = onSignInRequiredForCreate
        self.onOpenHostMessages = onOpenHostMessages
        self.tabChrome = tabChrome
        self.isActivityTabSelected = isActivityTabSelected
    }

    public var body: some View {
        compactRoot
        .environment(activityFavoriteStore)
        .environment(activityCreateTemplateStore)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            String(localized: "screen.activity", defaultValue: "活动", comment: "Activity screen")
        )
        .sheet(isPresented: $showMyActivities) {
            myActivitiesSheet
        }
        .sheet(isPresented: $showActivityReminders) {
            activityRemindersSheet
        }
        .sheet(isPresented: $showActivityToolbarActions) {
            activityToolbarActionsSheet
        }
        .onChange(of: showMyActivities) { _, isPresented in
            if !isPresented {
                myActivitiesNavigationPath = NavigationPath()
            }
        }
        .sheet(isPresented: $showCreateActivity) {
            NavigationStack {
                CreateActivityView(
                    viewModel: coordinator.makeCreateViewModel(
                        initialDraft: pendingCreateActivityDraft,
                        templateStore: activityCreateTemplateStore
                    ),
                    onCreated: { detail in
                        Task {
                            await onActivityCreated?(detail)
                            await viewModel.load()
                            openActivity(detail.id)
                        }
                    },
                    onProvisionGroupChat: onRSVPCompleted
                )
            }
        }
        .onChange(of: pendingCreateActivityDraft) { _, draft in
            guard let draft else { return }
            if isAuthenticated {
                showCreateActivity = true
            } else {
                onSignInRequiredForCreate?(draft)
            }
        }
        .onChange(of: showCreateActivity) { _, isPresented in
            if !isPresented {
                pendingCreateActivityDraft = nil
            }
        }
        .onChange(of: pendingActivityID) { _, activityID in
            guard let activityID else { return }
            Task { await openPendingActivity(activityID: activityID) }
        }
        .onAppear {
            if let activityID = pendingActivityID {
                Task { await openPendingActivity(activityID: activityID) }
            }
            ensureBrowseViewModelIfNeeded()
            if !isAuthenticated {
                selectedHomeSegment = .discover
            }
            tabChrome.navigation.isActivityTabSelected = isActivityTabSelected
            syncTabChrome()
        }
        .onChange(of: isActivityTabSelected) { _, isSelected in
            tabChrome.navigation.isActivityTabSelected = isSelected
            if isSelected {
                syncTabChrome()
            } else {
                tabChrome.reconcile()
            }
        }
        .onChange(of: selectedHomeSegment) { _, _ in
            syncTabChrome()
        }
        .onChange(of: navigationPath) { _, _ in
            syncTabChrome()
        }
        .onChange(of: showMyActivities) { _, _ in
            syncTabChrome()
        }
        .onChange(of: isAuthenticated) { _, authenticated in
            if authenticated {
                Task { await viewModel.load() }
                if pendingCreateActivityDraft != nil {
                    showCreateActivity = true
                }
            } else {
                selectedHomeSegment = .discover
                showMyActivities = false
                syncTabChrome()
            }
        }
    }
}

#Preview {
    ActivityRootView(coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository()))
}

#Preview("Activity — empty") {
    ActivityRootView(
        coordinator: ActivityCoordinator(feedRepository: EmptyActivityFeedRepository()),
        inboxViewModel: ActivityViewModel(repository: EmptyActivityFeedRepository())
    )
}

#Preview("Activity — error") {
    ActivityRootView(
        coordinator: ActivityCoordinator(feedRepository: FailingActivityFeedRepository()),
        inboxViewModel: ActivityViewModel(repository: FailingActivityFeedRepository())
    )
}

#Preview("Activity — dark") {
    SparkPreviewSupport.darkMode {
        ActivityRootView(coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository()))
    }
}

#Preview("Activity — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        ActivityRootView(coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository()))
    }
}

