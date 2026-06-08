// Module: SparkActivity — Activity tab root presentation.

import SparkDesignSystem
import SwiftUI

public struct ActivityRootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Binding var pendingActivityID: String?
    @Binding var pendingCreateActivityDraft: CreateActivityDraft?
    @State var viewModel: ActivityViewModel
    @State var navigationPath = NavigationPath()
    @State var selectedActivityID: String?

    let coordinator: ActivityCoordinator
    let onRSVPCompleted: ((ActivityDetail) async -> Void)?
    let onOpenGroupChat: ((ActivityDetail) async -> Void)?
    let onActivityCreated: ((ActivityDetail) async -> Void)?
    let isItemLocked: (Int) -> Bool
    let onLockedItemTap: (() -> Void)?
    let onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)?
    let onActivityRescheduled: ((ActivityDetail) async -> Void)?
    let onCommunityRecap: ((ActivityDetail) -> Void)?
    let onOpenUserProfile: ((String) -> Void)?
    let canAccessHostTools: () -> Bool
    let onHostToolsLocked: (() -> Void)?
    let inviteCandidates: () -> [ActivityInviteCandidate]
    let actionItemsInset: (ActivityListFilter) -> AnyView
    let requestActivityIDs: (ActivityListFilter) -> Set<String>

    @State var showCreateActivity = false
    @State var showNotificationSettings = false
    @State var showMineMap = false
    @State var browseViewModel: ActivityBrowseViewModel
    @State var selectedInboxSegment: ActivityInboxSegment
    @State var activityFavoriteStore = ActivityFavoriteStore()

    public init<ActionItems: View>(
        coordinator: ActivityCoordinator,
        pendingActivityID: Binding<String?> = .constant(nil),
        pendingCreateActivityDraft: Binding<CreateActivityDraft?> = .constant(nil),
        onRSVPCompleted: ((ActivityDetail) async -> Void)? = nil,
        onOpenGroupChat: ((ActivityDetail) async -> Void)? = nil,
        onActivityCreated: ((ActivityDetail) async -> Void)? = nil,
        isItemLocked: @escaping (Int) -> Bool = { _ in false },
        onLockedItemTap: (() -> Void)? = nil,
        onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)? = nil,
        onActivityRescheduled: ((ActivityDetail) async -> Void)? = nil,
        onCommunityRecap: ((ActivityDetail) -> Void)? = nil,
        onOpenUserProfile: ((String) -> Void)? = nil,
        canAccessHostTools: @escaping () -> Bool = { true },
        onHostToolsLocked: (() -> Void)? = nil,
        inviteCandidates: @escaping () -> [ActivityInviteCandidate] = { [] },
        @ViewBuilder actionItemsInset: @escaping (ActivityListFilter) -> ActionItems = { _ in EmptyView() },
        requestActivityIDs: @escaping (ActivityListFilter) -> Set<String> = { _ in [] }
    ) {
        self.coordinator = coordinator
        _pendingActivityID = pendingActivityID
        _pendingCreateActivityDraft = pendingCreateActivityDraft
        _viewModel = State(initialValue: coordinator.makeInboxViewModel())
        _browseViewModel = State(initialValue: coordinator.makeBrowseViewModel())
        _selectedInboxSegment = State(
            initialValue: coordinator.hasBrowseCatalog ? .discover : .mine
        )
        self.onRSVPCompleted = onRSVPCompleted
        self.onOpenGroupChat = onOpenGroupChat
        self.onActivityCreated = onActivityCreated
        self.isItemLocked = isItemLocked
        self.onLockedItemTap = onLockedItemTap
        self.onHostAnnouncePosted = onHostAnnouncePosted
        self.onActivityRescheduled = onActivityRescheduled
        self.onCommunityRecap = onCommunityRecap
        self.onOpenUserProfile = onOpenUserProfile
        self.canAccessHostTools = canAccessHostTools
        self.onHostToolsLocked = onHostToolsLocked
        self.inviteCandidates = inviteCandidates
        self.actionItemsInset = { filter in AnyView(actionItemsInset(filter)) }
        self.requestActivityIDs = requestActivityIDs
    }

    init<ActionItems: View>(
        viewModel: ActivityViewModel,
        coordinator: ActivityCoordinator,
        pendingActivityID: Binding<String?> = .constant(nil),
        pendingCreateActivityDraft: Binding<CreateActivityDraft?> = .constant(nil),
        onRSVPCompleted: ((ActivityDetail) async -> Void)? = nil,
        onOpenGroupChat: ((ActivityDetail) async -> Void)? = nil,
        onActivityCreated: ((ActivityDetail) async -> Void)? = nil,
        isItemLocked: @escaping (Int) -> Bool = { _ in false },
        onLockedItemTap: (() -> Void)? = nil,
        onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)? = nil,
        onActivityRescheduled: ((ActivityDetail) async -> Void)? = nil,
        onCommunityRecap: ((ActivityDetail) -> Void)? = nil,
        onOpenUserProfile: ((String) -> Void)? = nil,
        canAccessHostTools: @escaping () -> Bool = { true },
        onHostToolsLocked: (() -> Void)? = nil,
        inviteCandidates: @escaping () -> [ActivityInviteCandidate] = { [] },
        @ViewBuilder actionItemsInset: @escaping (ActivityListFilter) -> ActionItems = { _ in EmptyView() },
        requestActivityIDs: @escaping (ActivityListFilter) -> Set<String> = { _ in [] }
    ) {
        self.coordinator = coordinator
        _pendingActivityID = pendingActivityID
        _pendingCreateActivityDraft = pendingCreateActivityDraft
        _viewModel = State(initialValue: viewModel)
        _browseViewModel = State(initialValue: coordinator.makeBrowseViewModel())
        _selectedInboxSegment = State(
            initialValue: coordinator.hasBrowseCatalog ? .discover : .mine
        )
        self.onRSVPCompleted = onRSVPCompleted
        self.onOpenGroupChat = onOpenGroupChat
        self.onActivityCreated = onActivityCreated
        self.isItemLocked = isItemLocked
        self.onLockedItemTap = onLockedItemTap
        self.onHostAnnouncePosted = onHostAnnouncePosted
        self.onActivityRescheduled = onActivityRescheduled
        self.onCommunityRecap = onCommunityRecap
        self.onOpenUserProfile = onOpenUserProfile
        self.canAccessHostTools = canAccessHostTools
        self.onHostToolsLocked = onHostToolsLocked
        self.inviteCandidates = inviteCandidates
        self.actionItemsInset = { filter in AnyView(actionItemsInset(filter)) }
        self.requestActivityIDs = requestActivityIDs
    }

    var usesSplitLayout: Bool {
        horizontalSizeClass == .regular
    }

    public var body: some View {
        Group {
            if usesSplitLayout {
                splitRoot
            } else {
                compactRoot
            }
        }
        // REASONING: Split detail column is not a descendant of `activityListShell`; cover hero needs this.
        .environment(activityFavoriteStore)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            String(localized: "screen.activity", defaultValue: "活动", comment: "Activity screen")
        )
        .sheet(isPresented: $showNotificationSettings) {
            notificationSettingsSheet
        }
        .sheet(isPresented: $showMineMap) {
            NavigationStack {
                mineMapOverlay
                    .navigationTitle(
                        String(localized: "activity.segment.map", defaultValue: "地图", comment: "Map segment")
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "action.done", defaultValue: "完成", comment: "Done")) {
                                showMineMap = false
                            }
                        }
                    }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showCreateActivity) {
            NavigationStack {
                CreateActivityView(
                    viewModel: coordinator.makeCreateViewModel(initialDraft: pendingCreateActivityDraft),
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
            guard draft != nil else { return }
            showCreateActivity = true
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
        }
    }

}

#Preview {
    ActivityRootView(coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository()))
}

#Preview("Activity — empty") {
    ActivityRootView(
        viewModel: ActivityViewModel(repository: EmptyActivityFeedRepository()),
        coordinator: ActivityCoordinator(feedRepository: EmptyActivityFeedRepository())
    )
}

#Preview("Activity — error") {
    ActivityRootView(
        viewModel: ActivityViewModel(repository: FailingActivityFeedRepository()),
        coordinator: ActivityCoordinator(feedRepository: FailingActivityFeedRepository())
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

#Preview("Activity — iPad split") {
    SparkPreviewSupport.iPadRegular {
        ActivityRootView(coordinator: ActivityCoordinator(feedRepository: MockActivityFeedRepository()))
    }
}
