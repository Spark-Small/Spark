//
//  ProfileView.swift
//  坐标系
//
//  「我的」Tab 根：资料头 + 四档内容；顶栏通知+齿轮。
//  滚动骨架与活动/搭子同构：外层 spacing 0 + 内层 sectionSpacing（系统 List 分节顶距）。
//

import SwiftUI
import CoordinateModels

struct ProfileView: View {
    @Environment(AppModel.self) var app
    @Environment(BuddiesModel.self) var buddies
    @Environment(MessagesModel.self) var messages
    @Environment(CommunityModel.self) var community
    @Environment(ProductLifecycleStore.self) var lifecycle
    @Environment(InAppNotificationStore.self) var notificationInbox

    @State var navigateActivity: Activity?
    @State var navigation = TabNavigationState()
    @Namespace var activityZoomNamespace
    @State var homeContentTab: ProfileHomeContentTab = .posts

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var community = community

        NavigationStack(path: $navigation.path) {
            profileHome
                .platformTabRootToolbar { tabToolbar }
                .profileRootDestinations(
                    navigation: navigation,
                    buddies: buddies,
                    messages: messages,
                    app: app,
                    activityZoomNamespace: activityZoomNamespace
                )
                .activityMapNavigationSheet(activity: $navigateActivity)
                .sheet(
                    isPresented: $community.presentation.isComposing,
                    onDismiss: { community.presentation.endCompose() }
                ) {
                    CommunityComposeSheet()
                        .toolbarVisibility(.hidden, for: .tabBar)
                }
                .onAppear { consumePendingProfileNavigation() }
                .task { await notificationInbox.syncDeliveredFromSystem() }
                .onChange(of: app.pendingProfileRoute) { _, route in
                    guard route != nil else { return }
                    consumePendingProfileNavigation()
                }
                .onChange(of: app.mapNavigationActivity?.id, initial: true) { _, _ in
                    guard let activity = app.mapNavigationActivity else { return }
                    navigateActivity = activity
                    app.mapNavigationActivity = nil
                }
        }
        .tabNavigationState(navigation)
    }

    private var profileHome: some View {
        ScrollView {
            // 根层只用 VStack：四档内已有 LazyVGrid/LazyVStack，勿再套外层 Lazy（嵌套 lazy 滑动易卡死）。
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                    lifecycleTipBanner
                    profileHomeHero
                    profileHomeContent
                }
            }
            .discoverBrowsePageColumn()
        }
        .discoverBrowseScrollChrome()
        .scrollBounceBehavior(.basedOnSize)
        .platformTabRootScrollChrome(title: ProfileDashboardCopy.rootTitle)
        .refreshable { await app.resyncRemoteReadPath() }
    }

    @ToolbarContentBuilder
    private var tabToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                navigation.path.append(ProfileRoute.notifications)
            } label: {
                Image(systemName: notificationInbox.hasUnread ? "bell.badge.fill" : "bell.fill")
            }
            .badge(notificationInbox.unreadCount)
            .platformNavigationBarItemChrome()
            .accessibilityLabel(
                NotificationsCopy.accessibilityEntry(unread: notificationInbox.unreadCount)
            )
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                navigation.path.append(ProfileRoute.settings)
            } label: {
                Image(systemName: "gearshape.fill")
            }
            .platformNavigationBarItemChrome()
            .accessibilityLabel(ProfileDashboardCopy.settingsAccessibilityLabel)
        }
    }

    func consumePendingProfileNavigation() {
        guard let route = app.pendingProfileRoute else { return }
        app.pendingProfileRoute = nil
        app.pendingBookingID = nil
        // 深链重置栈，避免在已打开的子页上再叠一层同路由。
        navigation.path = NavigationPath()
        // 库类路由落在主页四档（页内直展）；其余仍 push。
        if let tab = ProfileHomeContentTab(profileRoute: route) {
            homeContentTab = tab
            return
        }
        navigation.path.append(route)
    }
}

#Preview {
    ProfileView()
}
