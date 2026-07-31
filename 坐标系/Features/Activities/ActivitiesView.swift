//
//  ActivitiesView.swift
//  坐标系
//

import SwiftUI

/// 活动发现：精选 Hero + 货架；详情 Zoom 打开。
struct ActivitiesView: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var didBootstrapLocation = false
    @State private var path = NavigationPath()
    @State private var seeAllShelf: ActivityBrowseShelf?
    @State private var showFavorites = false
    @Namespace private var zoomNamespace

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
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
            .scrollEdgeEffectStyle(.soft, for: .top)
            .background(PlatformSurface.groupedPage)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: PlatformMetrics.sectionSpacing)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { activitiesToolbar }
            // 精选时内容伸到顶边，玻璃顶栏由系统浮在内容上（非自算显隐）
            .ignoresSafeArea(edges: model.showsFeatured ? .top : [])
            .activityZoomNavigationDestination(namespace: zoomNamespace)
            .sheet(isPresented: $model.isComposing, onDismiss: {
                model.editingActivityID = nil
            }) {
                ActivityComposeSheet(
                    editingActivity: model.editingActivityID.flatMap { model.activity(id: $0) },
                    onPublish: handlePublish,
                    onUpdate: handleUpdate
                )
            }
            .sheet(isPresented: $showFavorites) {
                ActivityFavoritesView()
            }
            .sheet(isPresented: $model.showFilters) {
                ActivityFilterSheet(quickFilters: $model.quickFilters)
            }
            .sheet(item: $seeAllShelf) { shelf in
                ActivityCatalogSeeAllSheet(shelf: shelf)
            }
            .sheet(isPresented: joinSuccessPresented) {
                if let activity = model.joinSuccessActivity {
                    ActivityJoinSuccessSheet(
                        activity: activity,
                        context: .joined,
                        onOpenGroup: { openGroup(for: activity) },
                        onWriteRecap: { openCommunityRecap(for: activity) }
                    )
                }
            }
            .sheet(isPresented: publishSuccessPresented) {
                if let activity = model.publishSuccessActivity {
                    ActivityJoinSuccessSheet(
                        activity: activity,
                        context: .published,
                        onOpenGroup: { openGroup(for: activity) }
                    )
                }
            }
            .platformTransientFeedback($model.toastMessage)
            .task { await bootstrapLocationIfNeeded() }
            .platformTabBarHiddenWhenPushed(path.isEmpty)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var activitiesToolbar: some ToolbarContent {
        @Bindable var model = model

        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("分类", selection: $model.selectedCategory) {
                    ForEach(ActivityCategory.allCases) { category in
                        Label(category.title, systemImage: category.systemImage)
                            .tag(category)
                    }
                }
            } label: {
                Image(systemName: model.selectedCategory.systemImage)
                    .platformSymbolStyle(.hierarchical)
            }
            .platformToolbarCircleStyle()
            .accessibilityLabel("活动分类，当前\(model.selectedCategory.title)")
        }

        if hasActiveFilters {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    model.showFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .platformSymbolStyle(.hierarchical)
                }
                .platformToolbarCircleStyle()
                .accessibilityLabel(activeFiltersAccessibilityLabel)
                .accessibilityHint("打开筛选")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("发起活动", systemImage: "plus", action: beginCompose)
                Button("收藏的活动", systemImage: "bookmark") {
                    showFavorites = true
                }
                Button(
                    hasActiveFilters ? "筛选（已启用）" : "筛选",
                    systemImage: "line.3.horizontal.decrease"
                ) {
                    model.showFilters = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .platformSymbolStyle(.hierarchical)
            }
            .platformToolbarCircleStyle()
            .accessibilityLabel("更多")
        }
    }

    private var hasActiveFilters: Bool {
        !model.quickFilters.isEmpty || model.selectedCategory != .all
    }

    private var activeFiltersAccessibilityLabel: String {
        var parts: [String] = ["筛选中"]
        if model.selectedCategory != .all {
            parts.append(model.selectedCategory.title)
        }
        if !model.quickFilters.isEmpty {
            parts.append("\(model.quickFilters.count) 项条件")
        }
        return parts.joined(separator: "，")
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
        switch shelf.layout {
        case .editorial:
            DiscoverBrowseSection(
                title: shelf.title,
                subtitle: shelf.subtitle,
                onSeeAll: { seeAllShelf = shelf }
            ) {
                DiscoverHorizontalRail {
                    ForEach(shelf.activities) { activity in
                        PlatformEditorialCard(
                            activityID: activity.id,
                            zoomNamespace: zoomNamespace,
                            photo: activity.coverPhoto,
                            badge: editorialBadge(for: activity),
                            title: activity.title,
                            metaLine: editorialMeta(for: activity),
                            metaSymbol: activity.category.systemImage,
                            isJoined: model.isJoined(activity.id),
                            isFull: activity.isFull,
                            onJoin: { join(activity) }
                        )
                        .platformEditorialRailFrame()
                    }
                }
            }

        case .following:
            DiscoverBrowseSection(
                title: shelf.title,
                subtitle: shelf.subtitle,
                onSeeAll: { seeAllShelf = shelf }
            ) {
                DiscoverHorizontalRail {
                    ForEach(shelf.activities) { activity in
                        PlatformContinueCard(
                            activityID: activity.id,
                            zoomNamespace: zoomNamespace,
                            photo: activity.coverPhoto,
                            title: activity.title,
                            timeLine: Formatters.activityEventTime(from: activity.date),
                            metaLine: followingMeta(for: activity),
                            isJoined: model.isJoined(activity.id),
                            isFull: activity.isFull,
                            onJoin: model.isJoined(activity.id) ? nil : { join(activity) }
                        )
                        .platformContinueRailFrame()
                    }
                }
            }

        case .hot:
            DiscoverBrowseSection(
                title: shelf.title,
                subtitle: shelf.subtitle,
                onSeeAll: { seeAllShelf = shelf }
            ) {
                DiscoverHorizontalRail {
                    ForEach(shelf.activities) { activity in
                        PlatformEventCard(
                            activityID: activity.id,
                            zoomNamespace: zoomNamespace,
                            photo: activity.coverPhoto,
                            badge: hotBadge(for: activity),
                            title: activity.title,
                            timeLine: Formatters.activityEventTime(from: activity.date),
                            metaLine: hotMeta(for: activity),
                            isJoined: model.isJoined(activity.id),
                            isFull: activity.isFull,
                            onJoin: { join(activity) }
                        )
                        .platformContinueRailFrame()
                    }
                }
            }

        case .list:
            // 竖卡分区数量有限：用 VStack，避免嵌套纵向 LazyVStack
            DiscoverBrowseSection(
                title: shelf.title,
                subtitle: shelf.subtitle,
                onSeeAll: { seeAllShelf = shelf }
            ) {
                VStack(alignment: .leading, spacing: PlatformMetrics.discoverCardSpacing) {
                    ForEach(shelf.activities) { activity in
                        ActivityZoomNavigationLink(
                            activity: activity,
                            namespace: zoomNamespace
                        ) {
                            ActivityDiscoverCard(
                                activity: activity,
                                isJoined: model.isJoined(activity.id),
                                enablesOpenTap: false,
                                onJoin: { join(activity) }
                            )
                        }
                    }
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
            }

        case .ranked:
            DiscoverBrowseSection(
                title: shelf.title,
                subtitle: shelf.subtitle,
                onSeeAll: { seeAllShelf = shelf }
            ) {
                DiscoverHorizontalRail {
                    ForEach(Array(shelf.activities.enumerated()), id: \.element.id) { index, activity in
                        PlatformPosterRankCard(
                            activityID: activity.id,
                            zoomNamespace: zoomNamespace,
                            photo: activity.coverPhoto,
                            rank: index + 1,
                            title: activity.title,
                            genre: activity.category.title
                        )
                        .platformPosterRailFrame()
                    }
                }
            }
        }
    }

    /// 跟进轨：地点即可，不堆费用
    private func followingMeta(for activity: Activity) -> String {
        activity.districtLabel
    }

    /// 焦点大卡：品类 · 标签/费用 · 时间
    private func editorialMeta(for activity: Activity) -> String {
        let tag = activity.tags.first ?? (activity.isFree ? "免费" : activity.fee)
        let time = Formatters.activityEventTime(from: activity.date)
        return "\(activity.category.title) · \(tag) · \(time)"
    }

    private func editorialBadge(for activity: Activity) -> String? {
        ActivityCardStatus.captionBadge(for: activity, fallback: "新")
    }

    /// 热场轨：地点 · 费用或剩余席位
    private func hotMeta(for activity: Activity) -> String {
        if activity.isAlmostFull || activity.isFull {
            return "\(activity.districtLabel) · \(ActivityCardStatus.spotsText(for: activity, spaced: true))"
        }
        let fee = activity.isFree ? ActivityCardStatus.free : activity.fee
        return "\(activity.districtLabel) · \(fee)"
    }

    private func hotBadge(for activity: Activity) -> String? {
        ActivityCardStatus.captionBadge(
            for: activity,
            fallback: activity.category.shortTitle
        )
    }

    private var featuredCarousel: some View {
        // 单卡 Hero，不做分页轮播
        Group {
            if let featured = model.featured.first {
                ActivityFeaturedCard(
                    activity: featured,
                    zoomNamespace: zoomNamespace,
                    onJoin: { join(featured) }
                )
                // 身份只跟活动 id，避免报名后拆掉 Zoom 源
                .id(featured.id)
            }
        }
        .modifier(FeaturedHeroAspectModifier(dynamicTypeSize: dynamicTypeSize))
        .frame(maxWidth: .infinity)
        .clipped()
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
            get: { model.joinSuccessActivityID != nil && path.isEmpty },
            set: { if !$0 { model.dismissJoinSuccess() } }
        )
    }

    private var publishSuccessPresented: Binding<Bool> {
        Binding(
            get: { model.publishSuccessActivityID != nil && path.isEmpty },
            set: { if !$0 { model.dismissPublishSuccess() } }
        )
    }

    private func beginCompose() {
        model.editingActivityID = nil
        model.isComposing = true
    }

    private func open(_ activity: Activity) {
        path.append(ActivityZoomSource(activityID: activity.id, slot: "programmatic"))
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

/// 精选 Hero：常规字阶锁 3:4；无障碍大字号放开，让图下文不被裁切
private struct FeaturedHeroAspectModifier: ViewModifier {
    var dynamicTypeSize: DynamicTypeSize

    func body(content: Content) -> some View {
        if DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize) {
            content
        } else {
            content.aspectRatio(PlatformMetrics.featuredCardAspectRatio, contentMode: .fit)
        }
    }
}

#Preview {
    let app = AppModel()
    return ActivitiesView()
        .environment(app)
        .environment(app.activities)
        .environment(app.messages)
}
