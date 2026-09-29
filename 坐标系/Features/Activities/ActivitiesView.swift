//
//  ActivitiesView.swift
//  坐标系
//

import SwiftUI
import TipKit
import CoordinateModels
import CoordinateFeatureFlags

/// 活动发现：今日焦点 + App Store 式货架混排；详情 Zoom 打开。
struct ActivitiesView: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app
    @Environment(LocationService.self) private var location
    @State private var showWelcomeGuide = false
    @State private var navigateActivity: Activity?
    @State private var discoverBrowseScrollRequest = 0
    @State private var navigation = TabNavigationState()
    @Namespace private var zoomNamespace

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var model = model

        NavigationStack(path: $navigation.path) {
            ScrollViewReader { proxy in
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
                .searchable(text: $model.searchText, prompt: ActivityBrowseCopy.searchPrompt)
                .refreshable {
                    if FeatureFlags.useRemoteCatalog {
                        await app.resyncRemoteReadPath()
                    } else {
                        await model.reloadFromRepository()
                    }
                }
                .onChange(of: discoverBrowseScrollRequest) { _, _ in
                    PlatformMotion.withAnimation(.snappy) {
                        proxy.scrollTo(
                            ActivityBrowseCopy.ScrollAnchor.discoverBrowse,
                            anchor: .top
                        )
                    }
                }
            }
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
                openConversation: { conversationID in
                    openClubConversation(conversationID)
                }
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
                AppWelcomeGuideView { intent in
                    finishWelcomeGuide(with: intent)
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(isPresented: joinSuccessPresented) {
                if let activity = model.joinSuccessActivity {
                    ActivityJoinSuccessSheet(
                        activity: activity,
                        context: .joined,
                        onOpenJourney: { openJourney(activity) }
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
            .platformLightFeedback($model.lightFeedbackMessage)
            .platformFeedbackAlert($model.toastMessage)
            .activityMapNavigationSheet(activity: $navigateActivity)
            .onChange(of: app.mapNavigationActivity?.id, initial: true) { _, _ in
                guard let activity = app.mapNavigationActivity else { return }
                navigateActivity = activity
                app.mapNavigationActivity = nil
            }
            .onChange(of: showsJourneyNowPlayingBar, initial: true) { _, visible in
                app.activitiesTabNowPlayingBarVisible = visible
            }
            .onDisappear {
                app.activitiesTabNowPlayingBarVisible = false
            }
            .task(id: model.quickFilters.contains(.nearby)) { await bootstrapLocationIfNeeded() }
        }
        .tabNavigationState(navigation)
    }

    // MARK: - Browse

    @ViewBuilder
    private var browseContent: some View {
        browsePromoHeader

        if let spotlight = model.spotlightActivity {
            ActivityFeaturedSpotlightSection(
                activity: spotlight,
                zoomNamespace: zoomNamespace,
                onJoin: join
            )
            .activityZoomSlot("spotlight")
            .padding(.bottom, PlatformMetrics.sectionHeaderSpacing)
        }

        ActivityBrowseQuickFilterBar()
            .id(ActivityBrowseCopy.ScrollAnchor.discoverBrowse)

        LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
            ForEach(model.recommendationShelves) { shelf in
                ActivityBrowseShelfSection(
                    shelf: shelf,
                    zoomNamespace: zoomNamespace,
                    onJoin: join
                )
                .activityZoomSlot("shelf-\(shelf.id)")
            }

            if app.productLifecycleStore.shouldMergeCommunityIntoActivitiesTab {
                communityFeedEntry
            }
        }
    }

    @ViewBuilder
    private var browsePromoHeader: some View {
        switch browsePromoKind {
        case .nextUp(let summary):
            ActivityNextUpBanner(
                summary: summary,
                onOpenJourney: { openJourney(summary.activity) },
                onNavigate: { navigateActivity = summary.activity }
            )
            .id(summary.promoIdentity(calendarSyncRevision: model.calendarSyncRevision))
        case .discover:
            ActivityDiscoverPromoBanner(onDiscover: focusDiscoverBrowse)
        case nil:
            EmptyView()
        }
    }

    private var browsePromoKind: ActivityNextUpPresentation.BrowsePromoHeader? {
        ActivityNextUpPresentation.BrowsePromoHeader.resolve(
            hasSeenWelcomeGuide: app.welcomeGuide.hasSeenGuide,
            from: model
        )
    }

    private var communityFeedEntry: some View {
        DiscoverBrowseSection {
            DiscoverSectionTitleRow(
                title: CommunityCopy.embeddedEntryTitle,
                subtitle: CommunityCopy.embeddedEntrySubtitle,
                showsHorizontalInset: false
            )
        } content: {
            NavigationLink {
                CommunityFeedEmbeddedDestination()
            } label: {
                HStack(alignment: .center, spacing: PlatformMetrics.cardInfoSpacing) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PlatformAction.brandAccent)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                        Text(CommunityCopy.embeddedEntryTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(communityPreviewSubtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(PlatformMetrics.contentInset)
                .frame(maxWidth: .infinity, alignment: .leading)
                .platformThinMaterialBackground(in: PlatformMetrics.cardShape)
            }
            .buttonStyle(.plain)
        }
    }

    private var communityPreviewSubtitle: String {
        let count = app.community.items.count
        if count == 0 {
            return "看看大家分享的复盘与路线"
        }
        return "共 \(count) 条分享，点进看看最新复盘"
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
        !model.quickFilters.isEmpty
            || model.dayFilter != nil
            || !model.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var emptyState: some View {
        let filtered = hasActiveFilters || model.selectedCategory != .forYou
        let searching = !model.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return ContentUnavailableView {
            Label(
                searching
                    ? ActivityBrowseCopy.Empty.searchTitle
                    : (filtered ? ActivityBrowseCopy.Empty.filteredTitle : ActivityBrowseCopy.Empty.title),
                systemImage: searching
                    ? "magnifyingglass"
                    : (filtered ? "line.3.horizontal.decrease" : "calendar.badge.plus")
            )
        } description: {
            Text(
                searching
                    ? ActivityBrowseCopy.Empty.searchDescription
                    : (filtered
                        ? ActivityBrowseCopy.Empty.filteredDescription
                        : ActivityBrowseCopy.Empty.description)
            )
        } actions: {
            if searching {
                Button(ActivityBrowseCopy.Empty.clearSearchAction) {
                    model.searchText = ""
                }
                .activityPrimaryCTA(controlSize: .large)
            } else if filtered {
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

    private func presentWelcomeGuideIfNeeded() {
        guard !app.welcomeGuide.hasSeenGuide, !showWelcomeGuide else { return }
        showWelcomeGuide = true
    }

    private func finishWelcomeGuideIfNeeded() {
        guard !app.welcomeGuide.hasSeenGuide else { return }
        app.welcomeGuide.finish(app: app)
    }

    private func finishWelcomeGuide(with intent: AppWelcomeIntent) {
        app.welcomeGuide.finish(app: app, intent: intent)
    }

    private func focusDiscoverBrowse() {
        if let message = model.applyDiscoverPromoLanding() {
            model.flashLight(message)
        }
        discoverBrowseScrollRequest += 1
    }

    private var showsJourneyNowPlayingBar: Bool {
        guard app.welcomeGuide.hasSeenGuide else { return false }
        guard navigation.isEmpty else { return false }
        guard !showWelcomeGuide, !model.isComposing, !model.showFilters else { return false }
        guard model.joinSuccessActivityID == nil, model.publishSuccessActivityID == nil else { return false }
        return true
    }

    private func openJourney(_ activity: Activity) {
        navigation.path.append(
            ActivityZoomSource(
                activityID: activity.id,
                slot: "journey-todo",
                intent: .participantPass
            )
        )
    }

    private func open(_ activity: Activity) {
        navigation.path.append(ActivityZoomSource(activityID: activity.id, slot: "programmatic"))
    }

    private func consumePendingActivityOpen() {
        guard let id = app.pendingActivityID else { return }
        let followUp = app.pendingActivityFollowUp
        app.pendingActivityID = nil
        app.pendingActivityFollowUp = .none
        navigation.reset()

        switch followUp {
        case .none:
            navigation.path.append(ActivityZoomSource(activityID: id, slot: "notification"))
        case .openJourney:
            navigation.path.append(
                ActivityZoomSource(
                    activityID: id,
                    slot: "notification-journey",
                    intent: .participantPass
                )
            )
        case .journeyFeedback, .journeyRecap:
            app.pendingActivityJourneyFollowUp = followUp
            navigation.path.append(
                ActivityZoomSource(
                    activityID: id,
                    slot: "notification-journey",
                    intent: .participantPass
                )
            )
        }
    }

    private func join(_ activity: Activity) {
        PlatformMotion.withAnimation(.snappy) {
            _ = app.quickJoinActivity(activity) { open(activity) }
        }
    }

    private func openGroup(for activity: Activity) {
        app.activities.markActivityGroupOpened(activity.id)
        guard let route = app.prepareActivityGroupChatRoute(for: activity) else { return }
        navigation.openActivityGroupChat(for: activity, route: route)
    }

    private func openClubConversation(_ conversationID: UUID) {
        guard let conversation = messages.conversations.first(where: { $0.id == conversationID }),
              conversation.kind == .circle,
              let circleID = conversation.relatedCircleID,
              let circle = buddies.circle(id: circleID)
        else {
            app.openMessages(conversationID: conversationID)
            return
        }
        guard let route = app.prepareClubGroupChatRoute(for: circle) else { return }
        navigation.openClubGroupChat(for: circle, route: route)
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

    private func bootstrapLocationIfNeeded() async {
        guard model.quickFilters.contains(.nearby) else { return }
        location.promptWhenInUseIfNeeded()
        for _ in 0..<12 {
            if location.coordinate != nil { break }
            if !location.canPromptWhenInUse,
               !location.isAuthorized {
                break
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
        model.refreshDistancesFromLocation()
    }
}

#Preview {
    let app = AppModel.preview
    return ActivitiesView()
        .environment(app)
        .environment(app.activities)
        .environment(app.messages)
}
