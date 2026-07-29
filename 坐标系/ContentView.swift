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
    var auth = LocalAuthSession()
    var blockedUserNames: Set<String>
    var moderationTickets: [ModerationTicket]
    /// 跨 Tab 打开指定会话
    var pendingConversationID: ChatConversation.ID?
    /// 跨 Tab / 历史搜索定位到具体消息
    var pendingFocusMessageID: ChatMessage.ID?
    /// 跨 Tab 拉起通话页
    var pendingCallID: CallSessionRecord.ID?
    private let profileRepository: ProfileRepository
    @ObservationIgnored private var profilePersistenceGeneration: Int
    @ObservationIgnored private var profilePersistTask: Task<Void, Never>?
    @ObservationIgnored private let derivedStateService = AppDerivedStateService()
    @ObservationIgnored private lazy var syncOrchestrator = AppSyncOrchestrator(app: self)

    init(profileRepository: ProfileRepository? = nil) {
        let resolvedProfileRepository = profileRepository ?? LocalProfileRepository()
        self.profileRepository = resolvedProfileRepository
        profilePersistenceGeneration = resolvedProfileRepository.currentPersistenceGeneration()
        let profileSnapshot = resolvedProfileRepository.load()
        user = profileSnapshot.user
        hasCompletedOnboarding = profileSnapshot.hasCompletedOnboarding
        blockedUserNames = Set(profileSnapshot.blockedUserNames)
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

    func handle(_ event: AppDomainEvent) {
        syncOrchestrator.handle(event)
    }

    func updateProfile(_ updated: AppUser) {
        let previousName = user.name
        syncOrchestrator.handle(.profileUpdated(previousName: previousName, user: updated))
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

    /// 取消报名；付费活动可选演示退款；非主办则退出活动群
    func cancelActivityRegistration(_ id: Activity.ID, refundIfPaid: Bool = false) {
        let isHost = activities.isHost(id: id)
        if refundIfPaid, let order = ActivityPaymentStore.paidOrder(for: id) {
            _ = ActivityPaymentStore.requestRefund(orderID: order.id)
            ActivityPaymentStore.finalizeRefund(orderID: order.id)
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

    /// 列表/卡片快捷报名：无需 App 支付则直报，需支付则进详情
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
        return toggleJoinActivity(activity.id)
    }

    @discardableResult
    func startDirectChat(
        with nickname: String,
        greeting: String = MessagesCopy.defaultGreeting,
        deliverGreeting: Bool = true
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
        reloadFromLocalState(keepSignedIn: true)
    }

    func deleteLocalAccount() async {
        await quiesceAllPersistence()
        AppPersistence.resetLocalDemoData()
        ActivityEngagementStore.shared.reloadFromDisk()
        auth.resetStoredSession()
        reloadFromLocalState(keepSignedIn: false)
    }

    func persistProfile() {
        let snapshot = ProfileSnapshot(
            user: user,
            hasCompletedOnboarding: hasCompletedOnboarding,
            blockedUserNames: Array(blockedUserNames),
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
    @State private var model = AppModel()

    var body: some View {
        Group {
            if !model.auth.isSignedIn {
                RootView(session: model.auth)
            } else if !model.hasCompletedOnboarding {
                OnboardingSheet { interests in
                    model.completeOnboarding(interests: interests)
                }
            } else {
                mainTabs
            }
        }
        .task {
            await model.bootstrapAsync()
        }
        .animation(.spring(duration: 0.45, bounce: 0.12), value: model.auth.isSignedIn)
        .animation(.spring(duration: 0.4, bounce: 0.1), value: model.hasCompletedOnboarding)
    }

    private var mainTabs: some View {
        @Bindable var model = model

        // 官方 Tab + 下滑折叠收纳（iPhone：tabBarMinimizeBehavior）
        return TabView(selection: $model.selectedTab) {
            Tab("活动", systemImage: "calendar", value: .activities) {
                ActivitiesView()
                    .environment(model)
                    .environment(model.activities)
                    .environment(model.messages)
                    .environment(model.buddies)
                    .environment(model.community)
            }

            Tab("搭子", systemImage: "person.2", value: .buddies) {
                BuddiesView()
                    .environment(model)
                    .environment(model.activities)
                    .environment(model.messages)
                    .environment(model.buddies)
            }

            Tab("社区", systemImage: "bubble.left.and.bubble.right", value: .community) {
                CommunityView()
                    .environment(model)
                    .environment(model.community)
                    .environment(model.messages)
                    .environment(model.activities)
                    .environment(model.buddies)
            }

            Tab("消息", systemImage: "message", value: .messages) {
                MessagesView()
                    .environment(model)
                    .environment(model.messages)
                    .environment(model.activities)
                    .environment(model.buddies)
                    .environment(model.community)
            }
            .badge(model.messages.unreadTotal)

            Tab("我的", systemImage: "person.crop.circle", value: .profile) {
                ProfileView()
                    .environment(model)
                    .environment(model.activities)
                    .environment(model.messages)
                    .environment(model.buddies)
                    .environment(model.community)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .task {
            // 登录并完成引导后进入主界面时请求定位（仅系统未决定时会弹窗）
            LocationService.shared.promptWhenInUseIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}
