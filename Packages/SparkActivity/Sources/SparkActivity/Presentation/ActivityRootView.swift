// Module: SparkActivity — Activity tab root presentation.

import SparkDesignSystem
import SwiftUI

public struct ActivityRootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Binding var pendingActivityID: String?
    @State var viewModel: ActivityViewModel
    @State var navigationPath = NavigationPath()
    @State var selectedActivityID: String?

    let repository: any ActivityFeedRepository
    let blockedHostsStore: BlockedActivityHostsStore
    let browseRepository: (any ActivityBrowseRepository)?
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
        repository: any ActivityFeedRepository,
        blockedHostsStore: BlockedActivityHostsStore = BlockedActivityHostsStore(),
        browseRepository: (any ActivityBrowseRepository)? = nil,
        pendingActivityID: Binding<String?> = .constant(nil),
        onRSVPCompleted: ((ActivityDetail) async -> Void)? = nil,
        onOpenGroupChat: ((ActivityDetail) async -> Void)? = nil,
        onActivityCreated: ((ActivityDetail) async -> Void)? = nil,
        isItemLocked: @escaping (Int) -> Bool = { _ in false },
        onLockedItemTap: (() -> Void)? = nil,
        onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)? = nil,
        onActivityRescheduled: ((ActivityDetail) async -> Void)? = nil,
        onCommunityRecap: ((ActivityDetail) -> Void)? = nil
    ) {
        self.repository = repository
        self.blockedHostsStore = blockedHostsStore
        self.browseRepository = browseRepository
        _pendingActivityID = pendingActivityID
        _viewModel = State(initialValue: ActivityViewModel(repository: repository))
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
        repository: any ActivityFeedRepository,
        blockedHostsStore: BlockedActivityHostsStore = BlockedActivityHostsStore(),
        browseRepository: (any ActivityBrowseRepository)? = nil,
        pendingActivityID: Binding<String?> = .constant(nil),
        onRSVPCompleted: ((ActivityDetail) async -> Void)? = nil,
        onOpenGroupChat: ((ActivityDetail) async -> Void)? = nil,
        onActivityCreated: ((ActivityDetail) async -> Void)? = nil,
        isItemLocked: @escaping (Int) -> Bool = { _ in false },
        onLockedItemTap: (() -> Void)? = nil,
        onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)? = nil,
        onActivityRescheduled: ((ActivityDetail) async -> Void)? = nil,
        onCommunityRecap: ((ActivityDetail) -> Void)? = nil
    ) {
        self.repository = repository
        self.blockedHostsStore = blockedHostsStore
        self.browseRepository = browseRepository
        _pendingActivityID = pendingActivityID
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
        .sheet(isPresented: $showNotificationSettings) {
            notificationSettingsSheet
        }
        .sheet(isPresented: $showBrowse) {
            if let browseRepository {
                ActivityBrowseListView(
                    browseRepository: browseRepository,
                    feedRepository: repository,
                    blockedHostsStore: blockedHostsStore,
                    onRSVPCompleted: onRSVPCompleted,
                    onOpenGroupChat: onOpenGroupChat
                )
            }
        }
        .sheet(isPresented: $showCreateActivity) {
            NavigationStack {
                CreateActivityView(
                    repository: repository,
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
    ActivityRootView(repository: MockActivityFeedRepository())
}

#Preview("Activity — empty") {
    ActivityRootView(viewModel: ActivityViewModel(repository: EmptyActivityFeedRepository()), repository: EmptyActivityFeedRepository())
}

#Preview("Activity — error") {
    ActivityRootView(
        viewModel: ActivityViewModel(repository: FailingActivityFeedRepository()),
        repository: FailingActivityFeedRepository()
    )
}
