//
//  ProfileView.swift
//  坐标系
//
//  「我的」Tab 根：身份 / 凭证库 / 钱包 / 设置；分区见 +Sections，栈 chrome 见 +Chrome。
//

import SwiftUI
import CoordinateModels

struct ProfileView: View {
    @Environment(AppModel.self) var app
    @Environment(CommunityModel.self) var community
    @Environment(BuddiesModel.self) var buddies
    @Environment(MessagesModel.self) var messages
    @Environment(MembershipStore.self) var membership
    @Environment(ProductLifecycleStore.self) var lifecycle
    @Environment(PhotoVerificationStore.self) var photoVerification
    @Environment(InAppNotificationStore.self) var notificationInbox

    @State var showLikesReceivedInfo = false
    @State var youthBlockedMessage: String?
    @State var navigateActivity: Activity?
    @State var navigation = TabNavigationState()
    @Namespace var activityZoomNamespace

    var photoVerified: Bool {
        photoVerification.isVerified(for: app.user)
    }

    var body: some View {
        @Bindable var navigation = navigation

        NavigationStack(path: $navigation.path) {
            profileList
                .platformTabRootToolbar { tabToolbar }
                .profileRootPresentations(
                    app: app,
                    showLikesReceivedInfo: $showLikesReceivedInfo,
                    likesReceivedCount: ProfileSocialStats.likesReceived(
                        for: app.user.name,
                        community: community
                    ),
                    youthBlockedMessage: $youthBlockedMessage
                )
                .profileRootDestinations(
                    navigation: navigation,
                    buddies: buddies,
                    messages: messages,
                    app: app,
                    activityZoomNamespace: activityZoomNamespace
                )
                .activityMapNavigationSheet(activity: $navigateActivity)
                .onAppear {
                    consumePendingProfileNavigation()
                }
                .task {
                    await notificationInbox.syncDeliveredFromSystem()
                }
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

    private var profileList: some View {
        List {
            lifecycleTipSection
            identitySection
            lifePhotosSection
            servicesSection
            librarySection
        }
        .platformTabRootListChrome(title: ProfileDashboardCopy.rootTitle, compactSections: false)
        .refreshable {
            await app.resyncRemoteReadPath()
        }
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

    func openCommerce(_ action: () -> Void) {
        if YouthModePreference.isEnabled {
            youthBlockedMessage = CommerceAccessCopy.youthCommerceReason
            return
        }
        action()
    }

    func consumePendingProfileNavigation() {
        guard let route = app.pendingProfileRoute else { return }
        app.pendingProfileRoute = nil
        app.pendingBookingID = nil
        // 深链重置栈，避免在已打开的子页上再叠一层同路由。
        navigation.path = NavigationPath()
        navigation.path.append(route)
    }
}

#Preview {
    ProfileView()
}
