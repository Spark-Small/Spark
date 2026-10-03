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
    @Environment(ActivitiesModel.self) var activities
    @Environment(CommunityModel.self) var community
    @Environment(BuddiesModel.self) var buddies
    @Environment(MessagesModel.self) var messages
    @Environment(MembershipStore.self) var membership
    @Environment(ProductLifecycleStore.self) var lifecycle
    @Environment(PhotoVerificationStore.self) var photoVerification
    @Environment(InAppNotificationStore.self) var notificationInbox

    @State var showEditProfile = false
    @State var youthBlockedMessage: String?
    @State var showSettingsFromTip = false
    @State var navigateActivity: Activity?
    @State var navigation = TabNavigationState()
    @Namespace var activityZoomNamespace

    var photoVerified: Bool {
        photoVerification.isVerified(for: app.user)
    }

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var buddies = buddies

        NavigationStack(path: $navigation.path) {
            profileList
                .platformTabRootToolbar { tabToolbar }
                .profileRootPresentations(
                    app: app,
                    showEditProfile: $showEditProfile,
                    showSettingsFromTip: $showSettingsFromTip,
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
                .sheet(isPresented: $buddies.presentation.isComposingClub) {
                    CircleComposeSheet { circle in
                        if let convo = messages.startCircleChat(
                            for: circle,
                            memberName: app.user.name
                        ) {
                            buddies.attachJoinConversation(convo.id)
                        }
                    }
                    .toolbarVisibility(.hidden, for: .tabBar)
                }
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
            Group {
                lifecycleTipSection
                identitySection
                attentionSection
                servicesSection
                librarySection
            }
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
            NavigationLink {
                ProfileSettingsView()
                    .platformHiddenTabBar()
            } label: {
                Image(systemName: "gearshape.fill")
            }
            .platformNavigationBarItemChrome()
            .accessibilityLabel(ProfileDashboardCopy.settingsAccessibilityLabel)
        }
    }

    func openJourney(_ activity: Activity) {
        navigation.path.append(
            ActivityZoomSource(
                activityID: activity.id,
                slot: "profile-promo-journey",
                intent: .participantPass
            )
        )
    }

    func openIdentity() {
        showEditProfile = true
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
        navigation.path.append(route)
    }
}

#Preview {
    ProfileView()
}
