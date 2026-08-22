//
//  ContentView.swift
//  坐标系
//
//  Created by NMD on 2026/7/15.
//

import Observation
import SwiftUI

enum AppTab: Hashable {
    case activities
    case buddies
    case community
    case messages
    case profile
}

@MainActor
@Observable
final class AppModel {
    var selectedTab: AppTab = .activities
    var activities: ActivitiesModel
    var messages: MessagesModel
    var community: CommunityModel
    var buddies: BuddiesModel
    var user: AppUser
    var hasCompletedOnboarding: Bool
    var auth: LocalAuthSession
    var blockedUserNames: Set<String>
    var followedUserNames: Set<String>
    var moderationTickets: [ModerationTicket]
    /// 跨 Tab 打开指定会话
    var pendingConversationID: ChatConversation.ID?
    /// 跨 Tab / 历史搜索定位到具体消息
    var pendingFocusMessageID: ChatMessage.ID?
    /// 跨 Tab 拉起通话页
    var pendingCallID: CallSessionRecord.ID?
    /// 通知 / 深链打开活动详情
    var pendingActivityID: Activity.ID?
    /// 通知 / 深链打开陪玩预约（「我的 → 陪玩预约」）
    var pendingBookingID: BuddyBookingRecord.ID?
    var pendingProfileRoute: ProfileRoute?
    private let profileRepository: ProfileRepository
    @ObservationIgnored private var profilePersistenceGeneration: Int
    @ObservationIgnored private var profilePersistTask: Task<Void, Never>?
    @ObservationIgnored private let derivedStateService = AppDerivedStateService()
    @ObservationIgnored private lazy var syncOrchestrator = AppSyncOrchestrator(app: self)

    init(
        auth: LocalAuthSession? = nil,
        profileRepository: ProfileRepository? = nil
    ) {
        self.auth = auth ?? LocalAuthSession()
        let resolvedProfileRepository = profileRepository ?? LocalProfileRepository()
        self.profileRepository = resolvedProfileRepository
        profilePersistenceGeneration = resolvedProfileRepository.currentPersistenceGeneration()
        LocalUserIdentity.ensure()
        var profileSnapshot = resolvedProfileRepository.load()
        if profileSnapshot.user.id != LocalUserIdentity.current {
            profileSnapshot.user.id = LocalUserIdentity.current
        }
        user = profileSnapshot.user
        hasCompletedOnboarding = profileSnapshot.hasCompletedOnboarding
        blockedUserNames = Set(profileSnapshot.blockedUserNames)
        followedUserNames = Set(profileSnapshot.followedUserNames)
        moderationTickets = profileSnapshot.moderationTickets.sorted { $0.createdAt > $1.createdAt }
        BuddyMatchScorer.myInterests = profileSnapshot.user.interests.isEmpty
            ? SampleData.currentUserInterests
            : profileSnapshot.user.interests

        activities = ActivitiesModel(currentUserName: profileSnapshot.user.name)
        messages = MessagesModel()
        community = CommunityModel(currentUserName: profileSnapshot.user.name)
        buddies = BuddiesModel()
        buddies.blockedUserNames = blockedUserNames
        community.blockedUserNames = blockedUserNames
        wireFeatureCallbacks()
        syncRecommendationContext()
    }

    func bootstrapAsync() async {
        await quiesceAllPersistence()
        guard let profileSnapshot = try? await profileRepository.loadAsync() else { return }
        profilePersistenceGeneration = profileRepository.currentPersistenceGeneration()
        syncOrchestrator.handle(.localDataReloaded(profileSnapshot))

        await activities.reloadFromRepository()
        await messages.reloadFromRepository()
        await community.reloadFromRepository()
        await buddies.reloadFromRepository()

        buddies.blockedUserNames = blockedUserNames
        community.blockedUserNames = blockedUserNames
        wireFeatureCallbacks()
        syncOrchestrator.handle(.recommendationRefreshRequested)
    }

    func openMessages(
        conversationID: ChatConversation.ID,
        focusMessageID: ChatMessage.ID? = nil,
        callID: CallSessionRecord.ID? = nil
    ) {
        pendingConversationID = conversationID
        pendingFocusMessageID = focusMessageID
        pendingCallID = callID
        selectedTab = .messages
    }

    /// 通知 / 深链：切到活动 Tab 并打开详情
    func openActivity(_ id: Activity.ID) {
        pendingActivityID = id
        selectedTab = .activities
    }

    /// 通知：打开「我的 → 陪玩预约」（可定位到具体单）
    func openMyBookings(bookingID: BuddyBookingRecord.ID? = nil) {
        pendingBookingID = bookingID
        pendingProfileRoute = bookingID.map { .bookingDetail($0) } ?? .bookingCredentials
        selectedTab = .profile
    }

    func handleNotificationDeepLink(_ link: NotificationDeepLink) {
        switch link {
        case .activity(let id):
            openActivity(id)
        case .conversation(let id):
            openMessages(conversationID: id)
        case .booking(let id):
            openMyBookings(bookingID: id)
        }
    }

    func handle(_ event: AppDomainEvent) {
        syncOrchestrator.handle(event)
    }

    func updateProfile(_ updated: AppUser) {
        let previousName = user.name
        var next = updated
        next.id = LocalUserIdentity.current
        syncOrchestrator.handle(.profileUpdated(previousName: previousName, user: next))
    }

    func updateLookingFor(_ text: String) {
        var updated = user
        updated.lookingFor = text
        updateProfile(updated)
    }

    func syncProfileStats() {
        derivedStateService.refreshProfileStats(app: self)
    }

    @discardableResult
    func toggleJoinActivity(_ id: Activity.ID) -> Bool {
        let wasHost = activities.isHost(id: id)
        let joined = activities.toggleJoin(id)
        syncOrchestrator.handle(joined ? .activityJoined(id) : .activityLeft(id, wasHost: wasHost))
        return joined
    }

    /// 发布活动后创建群聊并同步资料统计
    func completeActivityPublish(_ id: Activity.ID) {
        syncOrchestrator.handle(.activityPublished(id))
    }

    /// 统一从任意 Tab 进入活动编辑（由活动 Tab 承载 Compose Sheet）
    func beginEditActivity(_ id: Activity.ID) {
        selectedTab = .activities
        activities.beginEdit(id)
    }

    /// 统一从任意 Tab 发起新活动（由活动 Tab 承载 Compose Sheet）
    func beginComposeActivity() {
        selectedTab = .activities
        activities.editingActivityID = nil
        activities.isComposing = true
    }

    /// 取消报名；非主办则退出活动群（退款请走 RefundFlowService）
    func cancelActivityRegistration(_ id: Activity.ID, refundIfPaid: Bool = false) {
        let isHost = activities.isHost(id: id)
        if refundIfPaid, let order = ActivityPaymentStore.paidOrder(for: id) {
            _ = RefundFlowService.shared.submitExpeditedActivityRefund(
                order: order,
                reason: "取消报名",
                detail: "用户取消参加活动，系统自动退款。"
            )
        }
        if activities.isJoined(id) {
            activities.toggleJoin(id)
        }
        syncOrchestrator.handle(.activityLeft(id, wasHost: isHost))
    }

    /// 主办取消活动：演示退款、群聊通知、移除活动
    func cancelHostedActivity(_ id: Activity.ID) {
        guard activities.isHost(id: id), activities.activity(id: id) != nil else { return }
        syncOrchestrator.handle(.activityCancelled(id))
    }

    /// 列表/卡片快捷报名：无需 App 支付则直报，需支付 / 有时间冲突则进详情确认
    @discardableResult
    func quickJoinActivity(_ activity: Activity, openDetail: @escaping () -> Void) -> Bool {
        if activity.isFull {
            openDetail()
            return false
        }
        if activity.requiresInAppPayment {
            openDetail()
            return false
        }
        if !activities.scheduleConflicts(with: activity).isEmpty {
            openDetail()
            return false
        }
        return toggleJoinActivity(activity.id)
    }

    @discardableResult
    func startDirectChat(
        with nickname: String,
        greeting: String = "",
        deliverGreeting: Bool = false
    ) -> ChatConversation? {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        if blockedUserNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            return nil
        }
        let before = Set(messages.conversations.map(\.id))
        let convo = messages.startChat(
            with: name,
            greeting: greeting,
            deliverGreeting: deliverGreeting
        )
        if let convo, !before.contains(convo.id) {
            syncProfileStats()
        }
        return convo
    }

    @discardableResult
    func startActivityGroupChat(for activity: Activity) -> ChatConversation? {
        let role: GroupChatJoinRole = activities.isHost(activity) ? .host : .participant
        return messages.startGroupChat(
            for: activity,
            role: role,
            memberName: user.name,
            announceMembership: false
        )
    }

    func openActivityGroupChat(for activity: Activity) {
        if let convo = startActivityGroupChat(for: activity) {
            openMessages(conversationID: convo.id)
        }
    }

    /// 活动改期 / 改标题后同步对应群聊
    func syncActivityGroupChat(for activityID: Activity.ID) {
        syncOrchestrator.handle(.activityUpdated(activityID))
    }

    func applyActivityUpdate(
        id: Activity.ID,
        title: String,
        category: ActivityCategory,
        location: String,
        date: Date,
        capacity: Int,
        fee: String,
        summary: String,
        tags: [String],
        localCoverName: String?,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        activities.update(
            id: id,
            title: title,
            category: category,
            location: location,
            date: date,
            capacity: capacity,
            fee: fee,
            summary: summary,
            tags: tags,
            localCoverName: localCoverName,
            latitude: latitude,
            longitude: longitude
        )
        syncOrchestrator.handle(.activityEdited(id))
    }

    func rescheduleHostedActivity(_ id: Activity.ID, to date: Date, notifyNote: String?) {
        activities.reschedule(id, to: date, notifyNote: notifyNote)
        if let activity = activities.activity(id: id) {
            WalletPassStore.shared.refreshActivityPass(activity: activity)
        }
        syncOrchestrator.handle(.activityEdited(id))
    }

    func beginCommunityRecap(for activity: Activity) {
        community.pendingRelatedActivityTitle = activity.title
        community.pendingRelatedActivityID = activity.id
        community.pendingComposeBody = "「\(activity.title)」复盘"
        community.isComposing = true
        selectedTab = .community
    }

    @discardableResult
    func shareCommunityPost(_ postID: CommunityPost.ID, to nickname: String) -> ChatConversation? {
        guard let post = community.post(id: postID) else { return nil }
        let message = post.messageText
        let preview = String(message.prefix(80))
        let convo = messages.shareCommunityPost(
            title: message,
            preview: preview,
            to: nickname,
            postID: post.id
        )
        if convo != nil {
            community.recordShare(postID)
        }
        return convo
    }

    func completeOnboarding(interests: [String]) {
        syncOrchestrator.handle(.onboardingCompleted(interests: interests))
    }

    func syncRecommendationContext() {
        derivedStateService.refreshRecommendations(app: self)
    }

    func refreshInterestContext(_ interests: [String]) {
        BuddyMatchScorer.myInterests = interests.isEmpty
            ? SampleData.currentUserInterests
            : interests
    }

    func isFollowing(_ name: String) -> Bool {
        followedUserNames.contains(name)
    }

    func toggleFollow(_ name: String) {
        if followedUserNames.contains(name) {
            followedUserNames.remove(name)
        } else {
            followedUserNames.insert(name)
        }
        persistProfile()
    }

    func blockUser(_ name: String) {
        syncOrchestrator.handle(.userBlocked(name))
    }

    func unblockUser(_ name: String) {
        syncOrchestrator.handle(.userUnblocked(name))
    }

    func addModerationTicket(
        postID: UUID,
        title: String,
        reason: String,
        targetKind: ModerationTargetKind = .communityPost
    ) {
        syncOrchestrator.handle(.moderationTicketAdded(
            ModerationTicket(
            id: UUID(),
            postID: postID,
            postTitle: title,
            reason: reason,
            createdAt: .now,
            status: .received,
            targetKind: targetKind
        )))
    }

    func advanceModerationTicket(_ id: ModerationTicket.ID) {
        guard let index = moderationTickets.firstIndex(where: { $0.id == id }) else { return }
        guard let next = moderationTickets[index].status.nextSimulated else { return }
        moderationTickets[index].status = next
        moderationTickets[index].updatedAt = .now
        persistProfile()
    }

    func rejectModerationTicket(_ id: ModerationTicket.ID) {
        guard let index = moderationTickets.firstIndex(where: { $0.id == id }) else { return }
        guard moderationTickets[index].status == .received
            || moderationTickets[index].status == .reviewing
        else { return }
        moderationTickets[index].status = .rejected
        moderationTickets[index].updatedAt = .now
        persistProfile()
    }

    func deleteModerationTicket(_ id: ModerationTicket.ID) {
        moderationTickets.removeAll { $0.id == id }
        persistProfile()
    }

    /// 本地登出：清登录态；可选重置引导
    func signOutLocally(clearOnboarding: Bool = true) async {
        await quiesceAllPersistence()
        auth.signOut()
        if clearOnboarding {
            hasCompletedOnboarding = false
        }
        persistProfile()
    }

    func clearLocalCaches() {
        // 演示：仅重置社区/搭子本地文件为 seed 较危险，改为清空拉黑与工单
        blockedUserNames = []
        moderationTickets = []
        buddies.blockedUserNames = []
        community.blockedUserNames = []
        persistProfile()
    }

    func resetLocalDemoData() async {
        await quiesceAllPersistence()
        AppPersistence.resetLocalDemoData()
        ActivityEngagementStore.shared.reloadFromDisk()
        ProfileRecentBrowseStore.shared.reloadFromDisk()
        reloadFromLocalState(keepSignedIn: true)
    }

    func deleteLocalAccount() async {
        await quiesceAllPersistence()
        AppPersistence.resetLocalDemoData()
        ActivityEngagementStore.shared.reloadFromDisk()
        ProfileRecentBrowseStore.shared.reloadFromDisk()
        auth.resetStoredSession()
        reloadFromLocalState(keepSignedIn: false)
    }

    func persistProfile() {
        let snapshot = ProfileSnapshot(
            user: user,
            hasCompletedOnboarding: hasCompletedOnboarding,
            blockedUserNames: Array(blockedUserNames),
            followedUserNames: Array(followedUserNames),
            moderationTickets: moderationTickets
        )
        let previousTask = profilePersistTask
        let generation = profilePersistenceGeneration
        profilePersistTask = Task {
            _ = await previousTask?.result
            guard !Task.isCancelled else { return }
            try? await profileRepository.replaceAsync(with: snapshot, generation: generation)
        }
    }

    private func reloadFromLocalState(keepSignedIn: Bool) {
        let profileSnapshot = profileRepository.load()
        profilePersistenceGeneration = profileRepository.currentPersistenceGeneration()
        var reloadedProfile = profileSnapshot
        if !keepSignedIn {
            reloadedProfile.hasCompletedOnboarding = false
        }
        syncOrchestrator.handle(.localDataReloaded(reloadedProfile))

        activities = ActivitiesModel(currentUserName: reloadedProfile.user.name)
        messages = MessagesModel()
        community = CommunityModel(currentUserName: reloadedProfile.user.name)
        buddies = BuddiesModel()
        buddies.blockedUserNames = blockedUserNames
        community.blockedUserNames = blockedUserNames
        wireFeatureCallbacks()
        selectedTab = .activities
        pendingConversationID = nil
        pendingFocusMessageID = nil
        pendingCallID = nil
        pendingActivityID = nil
        pendingBookingID = nil
        pendingProfileRoute = nil
        refreshInterestContext(reloadedProfile.user.interests)
        syncOrchestrator.handle(.recommendationRefreshRequested)
        syncOrchestrator.handle(.statsRefreshRequested)
    }

    private func quiesceAllPersistence() async {
        profilePersistTask?.cancel()
        await activities.discardPendingPersistence()
        await messages.discardPendingPersistence()
        await community.discardPendingPersistence()
        await buddies.discardPendingPersistence()
        _ = await profilePersistTask?.result
        profilePersistTask = nil
        profileRepository.invalidatePendingWrites()
        profilePersistenceGeneration = profileRepository.currentPersistenceGeneration()
    }

    private func wireFeatureCallbacks() {
        messages.onConversationsChanged = { [weak self] in
            self?.handle(.conversationsChanged)
        }
        buddies.onRecordsChanged = { [weak self] in
            self?.handle(.buddyRecordsChanged)
        }
        buddies.onMembershipChanged = { [weak self] in
            self?.handle(.recommendationRefreshRequested)
        }
    }
}

struct ContentView: View {
    /// 仅读 UserDefaults，足够画出未登录首帧。
    @State private var auth = LocalAuthSession()
    /// 登录后再构造，避免首帧前解码全量本地目录。
    @State private var model: AppModel?
    @State private var didRunDeferredStartup = false
    /// 已登录用户遇协议版本升级时需重新确认；未登录走登录页勾选。
    @State private var hasAcceptedLegalConsent = !LegalConsentPreference.needsConsent
    @State private var commercePeerContactRoute: PeerContactRoute?

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
                    LaunchSurface.stage
                        .ignoresSafeArea()
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
        .task(id: "\(auth.isSignedIn)-\(hasAcceptedLegalConsent)") {
            // 未登录也可做轻量目录刷新；敏感权限仍在登录同意与主界面后再申请。
            await runDeferredStartupIfNeeded()
            guard auth.isSignedIn else { return }
            // 已登录但协议版本升级、尚未在 Gate 同意时，先等同意。
            if !hasAcceptedLegalConsent, LegalConsentPreference.needsConsent { return }
            hasAcceptedLegalConsent = true
            await ensureModelReady()
        }
        .animation(.spring(duration: 0.45, bounce: 0.12), value: auth.isSignedIn)
        .animation(.spring(duration: 0.4, bounce: 0.1), value: model?.hasCompletedOnboarding)
        .animation(.easeOut(duration: 0.25), value: hasAcceptedLegalConsent)
    }

    @ViewBuilder
    private func signedInRoot(_ model: AppModel) -> some View {
        if !model.hasCompletedOnboarding {
            OnboardingSheet { interests in
                model.completeOnboarding(interests: interests)
            }
        } else {
            mainTabs(model)
        }
    }

    private func mainTabs(_ model: AppModel) -> some View {
        @Bindable var model = model

        // iOS 26 Tab：`Tab(_:systemImage:value:)` + 下滑收纳
        return TabView(selection: $model.selectedTab) {
            Tab("活动", systemImage: "calendar", value: AppTab.activities) {
                ActivitiesView()
            }

            Tab("搭子", systemImage: "person.2", value: AppTab.buddies) {
                BuddiesView()
            }

            Tab("广场", systemImage: "bubble.left.and.bubble.right", value: AppTab.community) {
                CommunityView()
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
        .environment(WalletStore.shared)
        .environment(WalletPassStore.shared)
        .environment(RefundFlowService.shared)
        .environment(PassUpdateWebService.shared)
        .tabBarMinimizeBehavior(.onScrollDown)
        .buddyInviteChrome(
            buddies: model.buddies,
            activities: model.activities
        )
        .peerContactDestination(route: $commercePeerContactRoute)
        .task {
            // 登录并完成引导后进入主界面时请求定位（仅系统未决定时会弹窗）
            LocationService.shared.promptWhenInUseIfNeeded()
            ProductLifecycleStore.shared.recordOpen()
            // 协议同意后：系统「跟踪」→「通知」Alert（未请求过且未决定时才弹）
            await PermissionLaunchPrompts.requestPostLoginChainIfNeeded()
        }
    }

    /// 首帧之后：刷新目录种子；Debug 自检也延后。
    private func runDeferredStartupIfNeeded() async {
        guard !didRunDeferredStartup else { return }
        didRunDeferredStartup = true

        await Task.detached(priority: .utility) {
            AppPersistence.refreshCatalogIfNeeded()
        }.value

        #if DEBUG
        LocalCommercialSelfTests.runCriticalChecks()
        #endif
    }

    private func ensureModelReady() async {
        await runDeferredStartupIfNeeded()
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
}
