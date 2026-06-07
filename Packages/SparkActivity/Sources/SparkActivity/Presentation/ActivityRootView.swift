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

    @State var showCreateActivity = false
    @State var showNotificationSettings = false
    @State var showBrowse = false

    public init(
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
        onCommunityRecap: ((ActivityDetail) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        _pendingActivityID = pendingActivityID
        _pendingCreateActivityDraft = pendingCreateActivityDraft
        _viewModel = State(initialValue: coordinator.makeInboxViewModel())
        self.onRSVPCompleted = onRSVPCompleted
        self.onOpenGroupChat = onOpenGroupChat
        self.onActivityCreated = onActivityCreated
        self.isItemLocked = isItemLocked
        self.onLockedItemTap = onLockedItemTap
        self.onHostAnnouncePosted = onHostAnnouncePosted
        self.onActivityRescheduled = onActivityRescheduled
        self.onCommunityRecap = onCommunityRecap
    }

    init(
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
        onCommunityRecap: ((ActivityDetail) -> Void)? = nil
    ) {
        self.coordinator = coordinator
        _pendingActivityID = pendingActivityID
        _pendingCreateActivityDraft = pendingCreateActivityDraft
        _viewModel = State(initialValue: viewModel)
        self.onRSVPCompleted = onRSVPCompleted
        self.onOpenGroupChat = onOpenGroupChat
        self.onActivityCreated = onActivityCreated
        self.isItemLocked = isItemLocked
        self.onLockedItemTap = onLockedItemTap
        self.onHostAnnouncePosted = onHostAnnouncePosted
        self.onActivityRescheduled = onActivityRescheduled
        self.onCommunityRecap = onCommunityRecap
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            String(localized: "screen.activity", defaultValue: "活动", comment: "Activity screen")
        )
        .sheet(isPresented: $showNotificationSettings) {
            notificationSettingsSheet
        }
        .sheet(isPresented: $showBrowse) {
            if coordinator.hasBrowseCatalog {
                ActivityBrowseListView(
                    coordinator: coordinator,
                    onRSVPCompleted: onRSVPCompleted,
                    onOpenGroupChat: onOpenGroupChat
                )
            }
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
