//
//  ActivitiesView.swift
//  坐标系
//

import SwiftUI
import TipKit

/// 活动发现：今日焦点 + App Store 式货架混排；详情 Zoom 打开。
struct ActivitiesView: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppWelcomeGuideCopy.storageKey) private var hasSeenAppWelcomeGuide = false
    @State private var didBootstrapLocation = false
    @State private var showWelcomeGuide = false
    @State private var navigation = TabNavigationState()
    @Namespace private var zoomNamespace

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var model = model

        NavigationStack(path: $navigation.path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if model.filtered.isEmpty {
                        emptyState
                    } else {
                        browseContent
                    }
                }
                .discoverBrowsePageColumn()
            }
            .discoverBrowseScrollChrome()
            .platformTabRootScrollChrome(title: model.selectedCategory.title)
            .platformTabRootTitleMenu {
                ActivityBrowseCategoryTitleMenu(selection: $model.selectedCategory)
            }
            .platformTabRootToolbar { tabToolbar }
            .tint(PlatformAction.cloverPurple)
            .activityZoomNavigationDestination(namespace: zoomNamespace)
            .activityPeerChatNavigationDestination()
            .circleBrowseStackChrome(
                buddies: buddies,
                openCircle: { navigation.openCircle($0) },
                openConversation: { app.openMessages(conversationID: $0) }
            )
            .onAppear {
                consumePendingActivityOpen()
                presentWelcomeGuideIfNeeded()
            }
            .onChange(of: app.pendingActivityID) { _, _ in
                consumePendingActivityOpen()
            }
            .sheet(isPresented: $model.isComposing, onDismiss: {
                model.editingActivityID = nil
            }) {
                ActivityComposeSheet(
                    editingActivity: model.editingActivityID.flatMap { model.activity(id: $0) },
                    onPublish: handlePublish,
                    onUpdate: handleUpdate
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: $model.showFilters) {
                ActivityFilterSheet(
                    quickFilters: $model.quickFilters,
                    dayFilter: $model.dayFilter
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(
                isPresented: $showWelcomeGuide,
                onDismiss: finishWelcomeGuideIfNeeded
            ) {
                AppWelcomeGuideView {
                    finishWelcomeGuideIfNeeded()
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: joinSuccessPresented) {
                if let activity = model.joinSuccessActivity {
                    ActivityJoinSuccessSheet(
                        activity: activity,
                        context: .joined,
                        onOpenGroup: { openGroup(for: activity) },
                        onWriteRecap: { openCommunityRecap(for: activity) }
                    )
                    .toolbarVisibility(.hidden, for: .tabBar)
                }
            }
            .sheet(isPresented: publishSuccessPresented) {
                if let activity = model.publishSuccessActivity {
                    ActivityJoinSuccessSheet(
                        activity: activity,
                        context: .published,
                        onOpenGroup: { openGroup(for: activity) }
                    )
                    .toolbarVisibility(.hidden, for: .tabBar)
                }
            }
            .platformFeedbackAlert($model.toastMessage)
            .task { await bootstrapLocationIfNeeded() }
        }
        .tabNavigationState(navigation)
    }

    // MARK: - Browse

    @ViewBuilder
    private var browseContent: some View {
        if let spotlight = model.spotlightActivity {
            ActivityFeaturedSpotlightSection(
                activity: spotlight,
                zoomNamespace: zoomNamespace,
                onJoin: join
            )
            .activityZoomSlot("spotlight")
            .padding(.bottom, PlatformMetrics.sectionSpacing)
        }

        LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
            ForEach(model.recommendationShelves) { shelf in
                ActivityBrowseShelfSection(
                    shelf: shelf,
                    zoomNamespace: zoomNamespace,
                    onJoin: join
                )
                .activityZoomSlot("shelf-\(shelf.id)")
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var tabToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("发起活动", systemImage: "plus", action: beginCompose)

            Button(
                hasActiveFilters ? "筛选（已启用）" : "筛选",
                systemImage: "line.3.horizontal.decrease"
            ) {
                model.showFilters = true
            }
            .symbolVariant(hasActiveFilters ? .fill : .none)
            .accessibilityHint("打开筛选")
            .popoverTip(ActivityFilterTip())
        }
    }

    private var hasActiveFilters: Bool {
        !model.quickFilters.isEmpty || model.dayFilter != nil
    }

    private var emptyState: some View {
        let filtered = hasActiveFilters || model.selectedCategory != .forYou
        return ContentUnavailableView {
            Label(
                filtered ? ActivityBrowseCopy.Empty.filteredTitle : ActivityBrowseCopy.Empty.title,
                systemImage: filtered ? "line.3.horizontal.decrease" : "calendar.badge.plus"
            )
        } description: {
            Text(
                filtered
                    ? ActivityBrowseCopy.Empty.filteredDescription
                    : ActivityBrowseCopy.Empty.description
            )
        } actions: {
            if filtered {
                Button(ActivityBrowseCopy.Empty.filteredAction) {
                    model.showFilters = true
                }
                .activityPrimaryCTA(controlSize: .large)
            } else {
                Button(ActivityBrowseCopy.Empty.action, action: beginCompose)
                    .activityPrimaryCTA(controlSize: .large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
    }

    // MARK: - Actions

    private var joinSuccessPresented: Binding<Bool> {
        Binding(
            get: { model.joinSuccessActivityID != nil && navigation.isEmpty },
            set: { if !$0 { model.dismissJoinSuccess() } }
        )
    }

    private var publishSuccessPresented: Binding<Bool> {
        Binding(
            get: { model.publishSuccessActivityID != nil && navigation.isEmpty },
            set: { if !$0 { model.dismissPublishSuccess() } }
        )
    }

    private func beginCompose() {
        model.editingActivityID = nil
        model.isComposing = true
    }

    /// 首次进入：等活动页内容出来后再盖半屏欢迎，让背后是真实活动界面。
    private func presentWelcomeGuideIfNeeded() {
        guard !hasSeenAppWelcomeGuide, !showWelcomeGuide else { return }
        showWelcomeGuide = true
    }

    private func finishWelcomeGuideIfNeeded() {
        guard !hasSeenAppWelcomeGuide else { return }
        hasSeenAppWelcomeGuide = true
        guard !app.hasCompletedOnboarding else { return }
        let interests = app.user.interests.isEmpty
            ? SampleData.currentUserInterests
            : app.user.interests
        app.completeOnboarding(interests: interests)
    }

    private func open(_ activity: Activity) {
        navigation.path.append(ActivityZoomSource(activityID: activity.id, slot: "programmatic"))
    }

    private func consumePendingActivityOpen() {
        guard let id = app.pendingActivityID else { return }
        app.pendingActivityID = nil
        navigation.reset()
        navigation.path.append(ActivityZoomSource(activityID: id, slot: "notification"))
    }

    private func join(_ activity: Activity) {
        withAnimation(reduceMotion ? nil : .snappy) {
            _ = app.quickJoinActivity(activity) { open(activity) }
        }
    }

    private func openGroup(for activity: Activity) {
        guard let route = app.prepareActivityGroupChatRoute(for: activity) else { return }
        navigation.openActivityGroupChat(for: activity, route: route)
    }

    private func handlePublish(
        _ title: String,
        _ category: ActivityCategory,
        _ location: String,
        _ date: Date,
        _ capacity: Int,
        _ fee: String,
        _ summary: String,
        _ tags: [String],
        _ cover: String?,
        _ lat: Double?,
        _ lon: Double?
    ) {
        guard let id = model.publish(
            title: title,
            category: category,
            location: location,
            date: date,
            capacity: capacity,
            fee: fee,
            summary: summary,
            tags: tags,
            localCoverName: cover,
            latitude: lat,
            longitude: lon
        ) else { return }

        app.handle(.activityPublished(id))
        if let activity = model.activity(id: id) {
            open(activity)
        }
    }

    private func handleUpdate(
        _ id: Activity.ID,
        _ title: String,
        _ category: ActivityCategory,
        _ location: String,
        _ date: Date,
        _ capacity: Int,
        _ fee: String,
        _ summary: String,
        _ tags: [String],
        _ cover: String?,
        _ lat: Double?,
        _ lon: Double?
    ) {
        app.applyActivityUpdate(
            id: id,
            title: title,
            category: category,
            location: location,
            date: date,
            capacity: capacity,
            fee: fee,
            summary: summary,
            tags: tags,
            localCoverName: cover,
            latitude: lat,
            longitude: lon
        )
    }

    private func openCommunityRecap(for activity: Activity) {
        app.beginCommunityRecap(for: activity)
    }

    private func bootstrapLocationIfNeeded() async {
        guard !didBootstrapLocation else { return }
        didBootstrapLocation = true
        LocationService.shared.promptWhenInUseIfNeeded()
        for _ in 0..<12 {
            if LocationService.shared.coordinate != nil { break }
            if !LocationService.shared.canPromptWhenInUse,
               !LocationService.shared.isAuthorized {
                break
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
        model.refreshDistancesFromLocation()
    }
}

#Preview {
    let app = AppModel()
    return ActivitiesView()
        .environment(app)
        .environment(app.activities)
        .environment(app.messages)
}
