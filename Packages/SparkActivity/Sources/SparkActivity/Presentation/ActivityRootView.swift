// Module: SparkActivity — Activity tab root presentation.

import SparkDesignSystem
import SwiftUI

public struct ActivityRootView: View {
    @Binding private var pendingActivityID: String?
    @State private var viewModel: ActivityViewModel
    @State private var navigationPath = NavigationPath()

    private let repository: any ActivityFeedRepository
    private let onRSVPCompleted: ((ActivityDetail) async -> Void)?
    private let onOpenGroupChat: ((ActivityDetail) async -> Void)?
    private let onActivityCreated: ((ActivityDetail) async -> Void)?
    private let isItemLocked: (Int) -> Bool
    private let onLockedItemTap: (() -> Void)?
    private let onHostAnnouncePosted: ((ActivityDetail, String) async -> Void)?
    private let onActivityRescheduled: ((ActivityDetail) async -> Void)?
    private let onCommunityRecap: ((ActivityDetail) -> Void)?

    @State private var showCreateActivity = false
    @State private var showNotificationSettings = false

    public init(
        repository: any ActivityFeedRepository,
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

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            SparkScreenContainer(
                navigationTitle: String(localized: "screen.activity", defaultValue: "活动", comment: "Activity screen"),
                embedding: .none
            ) {
                listContent
                    .task {
                        if viewModel.loadState == .idle {
                            await viewModel.load()
                        }
                    }
            }
            .navigationDestination(for: ActivityItem.self) { item in
                activityDetailView(activityID: item.id)
            }
            .navigationDestination(for: String.self) { activityID in
                externalActivityDetailView(activityID: activityID)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showNotificationSettings = true
                        } label: {
                            Label(
                                String(
                                    localized: "activity.settings.menu",
                                    defaultValue: "活动提醒",
                                    comment: "Activity settings"
                                ),
                                systemImage: "bell"
                            )
                        }
                        Button {
                            showCreateActivity = true
                        } label: {
                            Label(
                                String(localized: "activity.create.a11y", defaultValue: "创建活动", comment: "Create activity"),
                                systemImage: "plus"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showNotificationSettings) {
                NavigationStack {
                    Form {
                        ActivityNotificationSettingsSection()
                    }
                    .navigationTitle(
                        String(localized: "activity.settings.title", defaultValue: "活动设置", comment: "Settings title")
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "action.done", defaultValue: "完成", comment: "Done")) {
                                showNotificationSettings = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showCreateActivity) {
                NavigationStack {
                    CreateActivityView(
                        repository: repository,
                        onCreated: { detail in
                            Task {
                                await onActivityCreated?(detail)
                                await viewModel.load()
                                navigationPath.append(detail.asListItem())
                            }
                        },
                        onProvisionGroupChat: onRSVPCompleted
                    )
                }
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

    private func activityDetailView(activityID: String) -> some View {
        ActivityDetailView(
            activityID: activityID,
            repository: repository,
            context: .inbox,
            onRSVPCompleted: onRSVPCompleted,
            onOpenGroupChat: onOpenGroupChat,
            onActivityUpdated: { _ in await viewModel.load() },
            onHostAnnouncePosted: onHostAnnouncePosted,
            onActivityRescheduled: onActivityRescheduled,
            onCommunityRecap: onCommunityRecap
        )
    }

    private func externalActivityDetailView(activityID: String) -> some View {
        ActivityDetailView(
            activityID: activityID,
            repository: repository,
            context: .externalEntry,
            onRSVPCompleted: onRSVPCompleted,
            onOpenGroupChat: onOpenGroupChat,
            onActivityUpdated: { _ in await viewModel.load() },
            onHostAnnouncePosted: onHostAnnouncePosted,
            onActivityRescheduled: onActivityRescheduled,
            onCommunityRecap: onCommunityRecap
        )
    }

    @ViewBuilder
    private var listContent: some View {
        @Bindable var viewModel = viewModel
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            ContentUnavailableView(
                String(localized: "activity.empty.title", defaultValue: "暂无活动", comment: "Empty activity list"),
                systemImage: "calendar.badge.clock",
                description: Text(
                    String(localized: "activity.empty.subtitle", defaultValue: "稍后再来看看", comment: "Empty activity hint")
                )
            )
        case .failure(let message):
            SparkRetryUnavailableView(
                title: String(localized: "activity.error.title", defaultValue: "无法加载", comment: "Activity list error"),
                description: message
            ) {
                Task { await viewModel.load() }
            }
        case .loaded:
            VStack(spacing: 0) {
                Picker("", selection: $viewModel.listFilter) {
                    ForEach(ActivityListFilter.allCases) { filter in
                        Text(filter.localizedTitle).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if viewModel.showsFilterEmptyState {
                    ContentUnavailableView(
                        String(
                            localized: "activity.filter.empty.title",
                            defaultValue: "没有匹配的活动",
                            comment: "Filter empty"
                        ),
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text(
                            String(
                                localized: "activity.filter.empty.subtitle",
                                defaultValue: "试试其他筛选，或浏览全部活动。",
                                comment: "Filter empty hint"
                            )
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.filteredItems, id: \.id) { item in
                        let index = viewModel.items.firstIndex(where: { $0.id == item.id }) ?? 0
                        activityRow(for: item, at: index)
                    }
                    .sparkScreenListStyle()
                }
            }
        }
    }

    @ViewBuilder
    private func activityRow(for item: ActivityItem, at index: Int) -> some View {
        let locked = isItemLocked(index)
        if locked, let onLockedItemTap {
            Button(action: onLockedItemTap) {
                ActivityInboxListRow(item: item, isLocked: true)
            }
            .buttonStyle(.plain)
            .accessibilityHint(
                String(
                    localized: "activity.row.premium.hint",
                    defaultValue: "订阅后可查看",
                    comment: "Locked activity row"
                )
            )
        } else {
            NavigationLink(value: item) {
                ActivityInboxListRow(item: item, isLocked: false)
            }
            .accessibilityHint(
                String(
                    localized: "activity.row.openDetail.hint",
                    defaultValue: "查看活动邀请详情",
                    comment: "Activity row opens detail"
                )
            )
        }
    }

    private func openPendingActivity(activityID: String) async {
        navigationPath.append(activityID)
        pendingActivityID = nil
        if viewModel.loadState == .idle {
            await viewModel.load()
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
