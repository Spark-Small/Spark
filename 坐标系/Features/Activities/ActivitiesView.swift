//
//  ActivitiesView.swift
//  坐标系
//

import SwiftData
import SwiftUI
import CoordinateModels
import CoordinateFeatureFlags

/// 活动 Tab 栈内非 Zoom 目的地（与 `ActivityZoomSource` / `CircleBrowseRoute` 分流）。
enum ActivitiesBrowseRoute: Hashable {
    case communityFeed
}

/// 活动发现：转化优先货架；Tab 根官方顶栏；详情 Zoom。
struct ActivitiesView: View {
    @Environment(ActivitiesModel.self) var model
    @Environment(BuddiesModel.self) var buddies
    @Environment(MessagesModel.self) var messages
    @Environment(AppModel.self) var app
    @Environment(LocationService.self) var location
    @Query(sort: \RecentBrowseItem.viewedAt, order: .reverse)
    var browseItems: [RecentBrowseItem]
    @State var showWelcomeGuide = false
    @State private var navigateActivity: Activity?
    @State private var discoverBrowseScrollRequest = 0
    @State var navigation = TabNavigationState()
    @Namespace var zoomNamespace

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var model = model

        NavigationStack(path: $navigation.path) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear
                            .frame(height: 0)
                            .id(ActivityBrowseCopy.ScrollAnchor.discoverBrowse)

                        if model.isBrowsingRecents {
                            recentsBrowseContent
                        } else if model.filtered.isEmpty {
                            emptyState
                        } else {
                            browseContent
                        }
                    }
                    .discoverBrowsePageColumn()
                }
                .discoverBrowseScrollChrome()
                .platformTabRootScrollChrome(title: model.browseNavigationTitle)
                .platformTabRootTitleMenu {
                    ActivityBrowseCategoryTitleMenu(
                        category: $model.selectedCategory,
                        isBrowsingRecents: model.isBrowsingRecents,
                        hasRecents: hasActivityRecents,
                        onSelectCategory: { model.selectBrowseCategory($0) },
                        onSelectRecents: { model.selectBrowseRecents() }
                    )
                }
                .platformTabRootToolbar {
                    if !model.isBrowsingRecents {
                        ActivityBrowseTrailingToolbar(
                            quickFilters: $model.quickFilters,
                            nearbyRadiusKM: $model.nearbyFilterRadiusKM,
                            onCompose: beginCompose
                        )
                    }
                }
                .refreshable {
                    if FeatureFlags.useRemoteCatalog {
                        await app.resyncRemoteReadPath()
                    } else {
                        await model.reloadFromRepository()
                    }
                }
                .onChange(of: model.selectedCategory) { _, _ in
                    discoverBrowseScrollRequest += 1
                }
                .onChange(of: model.isBrowsingRecents) { _, _ in
                    discoverBrowseScrollRequest += 1
                }
                .onChange(of: hasActivityRecents) { _, hasRecents in
                    if !hasRecents, model.isBrowsingRecents {
                        model.selectBrowseCategory(.forYou)
                    }
                }
                .onChange(of: app.activitiesDiscoverBrowseFocusToken) { _, _ in
                    discoverBrowseScrollRequest += 1
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
            .navigationDestination(for: ActivitiesBrowseRoute.self) { route in
                switch route {
                case .communityFeed:
                    CommunityFeedStack(
                        presentation: .embedded,
                        zoomNamespace: zoomNamespace,
                        registersStackDestinations: false
                    )
                    .toolbarVisibility(.hidden, for: .tabBar)
                }
            }
            .navigationDestination(for: CommunityPost.self) { post in
                CommunityPostDetailView(postID: post.id)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .navigationDestination(for: CommunityLibraryDestination.self) { destination in
                CommunityLibraryRouter(destination: destination)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .onChange(of: app.pendingOpenEmbeddedCommunityFeed) { _, open in
                guard open else { return }
                app.pendingOpenEmbeddedCommunityFeed = false
                navigation.path.append(ActivitiesBrowseRoute.communityFeed)
            }
            .modifier(CommunityPendingPostNavigationModifier(path: $navigation.path))
            .activityZoomNavigationDestination(namespace: zoomNamespace)
            .activityPeerChatNavigationDestination()
            .circleBrowseStackChrome(
                buddies: buddies,
                messages: messages,
                memberName: app.user.name,
                blockedUserNames: app.blockedUserNames,
                onBrowseBuddies: { app.selectedTab = .buddies },
                openCircle: { navigation.openCircle($0) },
                openConversation: openClubConversation
            )
            .onAppear {
                consumePendingActivityOpen()
                presentWelcomeGuideIfNeeded()
            }
            .onChange(of: app.pendingActivityID) { _, _ in
                consumePendingActivityOpen()
            }
            .sheet(isPresented: $model.presentation.isComposing, onDismiss: {
                model.presentation.editingActivityID = nil
            }) {
                ActivityComposeSheet(
                    editingActivity: model.presentation.editingActivityID.flatMap { model.activity(id: $0) },
                    onPublish: handlePublish,
                    onUpdate: handleUpdate
                )
                .platformHiddenTabBar()
            }
            .sheet(
                isPresented: $showWelcomeGuide,
                onDismiss: finishWelcomeGuideIfNeeded
            ) {
                AppWelcomeGuideView { intent in
                    finishWelcomeGuide(with: intent)
                }
                .platformHiddenTabBar()
            }
            .sheet(isPresented: joinSuccessPresented) {
                if let activity = model.joinSuccessActivity {
                    ActivityJoinSuccessSheet(
                        activity: activity,
                        context: .joined,
                        onOpenJourney: { openJourney(activity) }
                    )
                    .platformHiddenTabBar()
                }
            }
            .sheet(isPresented: publishSuccessPresented) {
                if let activity = model.publishSuccessActivity {
                    ActivityJoinSuccessSheet(
                        activity: activity,
                        context: .published,
                        onOpenGroup: { openGroup(for: activity) }
                    )
                    .platformHiddenTabBar()
                }
            }
            .platformLightFeedback($model.presentation.lightFeedbackMessage)
            .platformFeedbackAlert($model.presentation.toastMessage)
            .activityMapNavigationSheet(activity: $navigateActivity)
            .onChange(of: app.mapNavigationActivity?.id, initial: true) { _, _ in
                guard let activity = app.mapNavigationActivity else { return }
                navigateActivity = activity
                app.mapNavigationActivity = nil
            }
            .task(id: model.quickFilters.contains(.nearby)) { await bootstrapLocationIfNeeded() }
        }
        .tabNavigationState(navigation)
    }
}

#Preview {
    let app = AppModel.preview
    return ActivitiesView()
        .environment(app)
        .environment(app.activities)
        .environment(app.messages)
}
