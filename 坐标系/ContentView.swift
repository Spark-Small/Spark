//
//  ContentView.swift
//  坐标系
//
//  Created by NMD on 2026/7/15.
//

import SwiftUI
import CoordinateModels

struct ContentView: View {
    /// 仅读 UserDefaults，足够画出未登录首帧。
    @State private var auth = LocalAuthSession()
    /// 登录后再构造，避免首帧前解码全量本地目录。
    @State private var model: AppModel?
    @State private var didRunDeferredStartup = false
    /// 已登录用户遇协议版本升级时需重新确认；未登录走登录页勾选。
    @State private var hasAcceptedLegalConsent = !LegalConsentPreference.needsConsent
    @State private var commercePeerContactRoute: PeerContactRoute?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if auth.isSignedIn, !hasAcceptedLegalConsent {
                LegalConsentGate {
                    hasAcceptedLegalConsent = true
                }
            } else if !auth.isSignedIn {
                RootView(session: auth)
            } else if let model {
                signedInRoot(model)
            } else {
                // 已登录冷启动：延续启动屏底色，等模型就绪后再进主界面。
                GeometryReader { proxy in
                    LaunchStageBackground()
                        .overlay {
                            Image("BrandLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .accessibilityHidden(true)
                                .position(
                                    x: proxy.size.width / 2,
                                    y: proxy.size.height / 2
                                )
                        }
                }
                .ignoresSafeArea()
            }
        }
        .onChange(of: auth.isSignedIn, initial: true) { _, isSignedIn in
            syncSignedInModelPresence(isSignedIn: isSignedIn)
        }
        .onChange(of: hasAcceptedLegalConsent) { _, _ in
            syncSignedInModelPresence(isSignedIn: auth.isSignedIn)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .background, let model else { return }
            model.flushPersistenceForBackground()
        }
        .task(id: "\(auth.isSignedIn)-\(hasAcceptedLegalConsent)") {
            // 未登录也可做轻量目录刷新；敏感权限仍在登录同意与主界面后再申请。
            await runDeferredStartupIfNeeded()
            if await AppleSignInService.refreshCredentialStateIfNeeded(),
               auth.provider == .apple {
                auth.signOut()
            }
            guard auth.isSignedIn else { return }
            // 已登录但协议版本升级、尚未在 Gate 同意时，先等同意。
            if !hasAcceptedLegalConsent, LegalConsentPreference.needsConsent { return }
            hasAcceptedLegalConsent = true
            await ensureModelReady()
        }
        .platformAnimation(.spring(duration: 0.45, bounce: 0.12), value: auth.isSignedIn)
        .platformAnimation(.spring(duration: 0.4, bounce: 0.1), value: model?.hasCompletedWelcomeBootstrap)
        .platformAnimation(.easeOut(duration: 0.25), value: hasAcceptedLegalConsent)
    }

    @ViewBuilder
    private func signedInRoot(_ model: AppModel) -> some View {
        VStack(spacing: 0) {
            PersistenceRecoveryBanner()
            mainTabs(model)
        }
            .onAppear {
                if !model.welcomeGuide.hasSeenGuide {
                    model.selectedTab = .activities
                }
            }
    }

    private func mainTabs(_ model: AppModel) -> some View {
        @Bindable var model = model
        let mergesCommunity = model.productLifecycleStore.shouldMergeCommunityIntoActivitiesTab

        // iOS 26 Tab：`Tab(_:systemImage:value:)` + 下滑收纳
        return TabView(selection: $model.selectedTab) {
            Tab("活动", systemImage: "calendar", value: AppTab.activities) {
                ActivitiesView()
            }

            Tab("搭子", systemImage: "person.2", value: AppTab.buddies) {
                BuddiesView()
            }

            if !mergesCommunity {
                Tab("广场", systemImage: "bubble.left.and.bubble.right", value: AppTab.community) {
                    CommunityView()
                }
            }

            Tab("消息", systemImage: "message", value: AppTab.messages) {
                MessagesView()
            }
            .badge(model.messages.unreadTotal)

            Tab("我的", systemImage: "person.crop.circle", value: AppTab.profile) {
                ProfileView()
            }
        }
        .environment(model)
        .environment(model.activities)
        .environment(model.messages)
        .environment(model.buddies)
        .environment(model.community)
        .environment(\.activityEngagementStore, model.activityEngagementStore)
        .environment(\.profileRecentBrowseStore, model.profileRecentBrowseStore)
        .environment(model.walletStore)
        .environment(model.membershipStore)
        .environment(model.notificationPreferencesStore)
        .environment(model.privacyPreferencesStore)
        .environment(model.youthModeStore)
        .environment(model.legalConsentStore)
        .environment(model.membershipAdImpressionStore)
        .environment(model.photoVerificationStore)
        .environment(model.opsContentStore)
        .environment(model.walletPassStore)
        .environment(model.refundFlowService)
        .environment(model.trustService)
        .environment(model.productLifecycleStore)
        .environment(PassUpdateWebService.shared)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(
            isEnabled: model.selectedTab == .activities && model.activitiesTabNowPlayingBarVisible
        ) {
            ActivityJourneyNowPlayingBar(
                snapshot: ActivityJourneyNowPlayingPresentation.snapshot(
                    for: model.activities,
                    hasSeenWelcomeGuide: model.welcomeGuide.hasSeenGuide
                ),
                onOpenJourney: { model.openActivityJourney($0.id) },
                onNavigate: { model.requestActivityMapNavigation($0) },
                onOpenProfileJourneys: { model.selectedTab = .profile }
            )
            .id(
                ActivityNextUpPresentation.nowPlayingBarIdentity(
                    for: model.activities,
                    hasSeenWelcomeGuide: model.welcomeGuide.hasSeenGuide
                )
            )
        }
            .buddyBookingSharedSheets(
                buddies: model.buddies,
                app: model,
                peerContactRoute: $commercePeerContactRoute
            )
            .buddyInviteChrome(
            buddies: model.buddies,
            activities: model.activities
        )
        .peerContactDestination(route: $commercePeerContactRoute)
        .sheet(isPresented: $model.pendingIdentityVerification) {
            IdentityVerificationSheet()
                .environment(model)
                .environment(model.photoVerificationStore)
                .environment(model.trustService)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $model.pendingIdentityEditProfile) {
            EditProfileSheet(user: Binding(
                get: { model.user },
                set: { model.updateProfile($0) }
            ))
            .environment(model)
            .environment(model.photoVerificationStore)
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .onAppear {
            if mergesCommunity, model.selectedTab == .community {
                model.selectedTab = .activities
            }
            model.productLifecycleStore.recordTabVisit(model.selectedTab)
        }
        .task {
            model.productLifecycleStore.recordOpen()
        }
        .onChange(of: model.selectedTab) { _, tab in
            if mergesCommunity, tab == .community {
                model.selectedTab = .activities
            } else {
                model.productLifecycleStore.recordTabVisit(tab)
            }
        }
    }

    /// 首帧之后：刷新目录种子；Debug 自检也延后。
    private func runDeferredStartupIfNeeded() async {
        guard !didRunDeferredStartup else { return }
        didRunDeferredStartup = true

        await Task { @MainActor in
            await AppComposition.bootstrapPersistence()
            AppPersistence.refreshCatalogIfNeeded()
        }.value

        #if DEBUG
        AppComposition.walletStore.purgeDebugSelfTestBookingCharges()
        #endif
    }

    /// 已登录且协议已放行时构造 `AppModel`（持久化预热完成后）。
    private func syncSignedInModelPresence(isSignedIn: Bool) {
        if !isSignedIn {
            model = nil
        }
    }

    private func ensureModelReady() async {
        await runDeferredStartupIfNeeded()
        guard auth.isSignedIn else { return }
        if !hasAcceptedLegalConsent, LegalConsentPreference.needsConsent { return }
        hasAcceptedLegalConsent = true
        if model == nil {
            model = AppModel(auth: auth)
        }
        if let model {
            AppNotificationRouter.shared.bind(model)
            await model.bootstrapAsync()
        }
    }
}

#Preview {
    ContentView()
        .platformChromeMeasurementsEnvironment()
}
