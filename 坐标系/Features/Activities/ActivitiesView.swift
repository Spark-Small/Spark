//
//  ActivitiesView.swift
//  坐标系
//

import SwiftUI

/// 活动发现：精选 Hero + 货架；详情 Zoom 打开。
struct ActivitiesView: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var didBootstrapLocation = false
    @State private var navigation = TabNavigationState()
    @State private var seeAllShelf: ActivityBrowseShelf?
    @State private var showLayoutDemo = false
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
                        if model.showsFeatured {
                            featuredCarousel
                        }

                        LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                            catalogStyleModules
                        }
                        .padding(.top, model.showsFeatured ? PlatformMetrics.sectionSpacing : 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, PlatformMetrics.sectionSpacing)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(PlatformSurface.groupedPage)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: PlatformMetrics.sectionSpacing)
            }
            .platformTabRootScrollChrome(title: model.selectedCategory.title)
            .platformTabRootTitleMenu {
                ActivityBrowseCategoryTitleMenu(selection: $model.selectedCategory)
            }
            .platformTabRootToolbar { tabToolbar }
            .tint(PlatformAction.cloverPurple)
            .activityZoomNavigationDestination(namespace: zoomNamespace)
            .circleBrowseStackChrome(
                buddies: buddies,
                openCircle: { navigation.openCircle($0) },
                openConversation: { app.openMessages(conversationID: $0) }
            )
            .onAppear { consumePendingActivityOpen() }
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
            .sheet(item: $seeAllShelf) { shelf in
                ActivityCatalogSeeAllSheet(shelf: shelf)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: $showLayoutDemo) {
                ActivityLayoutDemoView()
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
            .platformTransientFeedback($model.toastMessage)
            .task { await bootstrapLocationIfNeeded() }
        }
        .tabNavigationState(navigation)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var tabToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("布局演示", systemImage: "square.grid.2x2") {
                showLayoutDemo = true
            }
            .accessibilityHint("打开 Apple TV 式布局演示")

            Button("发起活动", systemImage: "plus", action: beginCompose)

            Button(
                hasActiveFilters ? "筛选（已启用）" : "筛选",
                systemImage: "line.3.horizontal.decrease"
            ) {
                model.showFilters = true
            }
            .symbolVariant(hasActiveFilters ? .fill : .none)
            .accessibilityHint("打开筛选")
        }
    }

    private var hasActiveFilters: Bool {
        !model.quickFilters.isEmpty || model.dayFilter != nil
    }

    // MARK: - 长列表推荐分区

    @ViewBuilder
    private var catalogStyleModules: some View {
        ForEach(model.recommendationShelves) { shelf in
            // 按货架分槽，保证同活动多处出现时 zoom 源 id 唯一
            shelfModule(shelf)
                .activityZoomSlot("shelf-\(shelf.id)")
        }
    }

    @ViewBuilder
    private func shelfModule(_ shelf: ActivityBrowseShelf) -> some View {
        ActivityBrowseShelfSection(
            shelf: shelf,
            zoomNamespace: zoomNamespace,
            onSeeAll: { seeAllShelf = shelf },
            onJoin: join
        )
    }

    private var featuredCarousel: some View {
        Group {
            if let featured = model.featured.first {
                ActivityFeaturedCard(
                    activity: featured,
                    zoomNamespace: zoomNamespace,
                    onJoin: { join(featured) }
                )
                .id(featured.id)
            }
        }
        .modifier(ActivityFeaturedHeroAspectModifier(dynamicTypeSize: dynamicTypeSize))
        .discoverBrowseContentInset()
        .frame(maxWidth: .infinity)
        .activityZoomSlot("featured")
    }

    private var emptyState: some View {
        let filtered = hasActiveFilters
        return ContentUnavailableView {
            Label(
                filtered ? ActivityBrowseCopy.Empty.filteredTitle : ActivityBrowseCopy.Empty.title,
                systemImage: filtered ? "line.3.horizontal.decrease" : "sparkles"
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
        app.openActivityGroupChat(for: activity)
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
