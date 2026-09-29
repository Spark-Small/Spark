//
//  ActivitiesModel.swift
//  坐标系
//

import CoordinateDomain
import Foundation
import Observation

@MainActor
@Observable
final class ActivitiesModel {
    var selectedCategory: ActivityCategory = .forYou
    var quickFilters: Set<ActivityQuickFilter> = []
    /// 按自然日筛选；`nil` 表示不限日期（替代筛选里的今天 / 明天分段）
    var dayFilter: Date? = nil
    /// 活动文字搜索（标题 / 地点 / 主办 / 标签）
    var searchText = ""
    var activities: [Activity]
    var favoriteIDs: Set<UUID>
    var joinedIDs: Set<UUID>
    var waitlistIDs: Set<UUID>
    var currentUserName: String
    var isComposing = false
    var editingActivityID: Activity.ID?
    var showFilters = false
    var joinSuccessActivityID: Activity.ID?
    /// 发起人发布成功（与参加成功区分）
    var publishSuccessActivityID: Activity.ID?
    var toastMessage: String?
    var lightFeedbackMessage: String?
    var waitlistSpotNotifiedIDs: Set<UUID>
    var participationProgress: [ActivityParticipationProgress]
    /// 日历写入不经过本 Model，用 revision 驱动待办 / 行程 UI 同步。
    var calendarSyncRevision = 0
    /// 欢迎引导等程序触发的 chip 高亮脉冲
    var quickFilterHighlightToken = 0
    var lastHighlightedQuickFilter: ActivityQuickFilter?
    var feedbackTagCounts: [String: [String: Int]]
    let repository: any ActivitiesRepository
    @ObservationIgnored let engagementStore: ActivityEngagementStore
    @ObservationIgnored let recentBrowseStore: ProfileRecentBrowseStore
    @ObservationIgnored let walletPassStore: WalletPassStore
    @ObservationIgnored let locationService: LocationService
    @ObservationIgnored let participation: ActivitiesParticipationUseCases
    @ObservationIgnored let browse: ActivitiesBrowseUseCases
    @ObservationIgnored var persistenceGeneration: Int
    @ObservationIgnored var persistTask: Task<Void, Never>?
    /// 货架结果缓存：避免每次 body / 返回发现页都整库重排
    @ObservationIgnored var cachedRecommendationShelves: [ActivityBrowseShelf] = []
    @ObservationIgnored var recommendationShelvesCacheKey: RecommendationShelvesCacheKey?

    init(
        repository: any ActivitiesRepository,
        engagementStore: ActivityEngagementStore,
        participation: ActivitiesParticipationUseCases,
        browse: ActivitiesBrowseUseCases,
        recentBrowseStore: ProfileRecentBrowseStore,
        walletPassStore: WalletPassStore,
        locationService: LocationService,
        currentUserName: String? = nil
    ) {
        self.repository = repository
        self.engagementStore = engagementStore
        self.participation = participation
        self.browse = browse
        self.recentBrowseStore = recentBrowseStore
        self.walletPassStore = walletPassStore
        self.locationService = locationService
        let snapshot = repository.load()
        activities = snapshot.activities
        joinedIDs = Set(snapshot.joinedIDs)
        favoriteIDs = Set(snapshot.favoriteIDs)
        waitlistIDs = Set(snapshot.waitlistIDs)
        waitlistSpotNotifiedIDs = Set(snapshot.waitlistSpotNotifiedIDs)
        participationProgress = snapshot.participationProgress
        feedbackTagCounts = snapshot.feedbackTagCounts
        self.currentUserName = currentUserName ?? SampleData.currentUser.name
        persistenceGeneration = repository.currentPersistenceGeneration()
        refreshDistancesFromLocation()
    }


    var joinedActivities: [Activity] {
        activities.filter { joinedIDs.contains($0.id) }.sorted { $0.date < $1.date }
    }

    var hostedActivities: [Activity] {
        activities
            .filter { $0.hostName == currentUserName }
            .sorted { $0.date < $1.date }
    }

    /// 邀约 / 群聊可选：已参加 + 我发起的，未结束
    var inviteableActivities: [Activity] {
        activities
            .filter {
                !$0.isLifecycleEnded
                    && (joinedIDs.contains($0.id) || $0.hostName == currentUserName)
            }
            .sorted { $0.date < $1.date }
    }

    var favoriteActivities: [Activity] {
        activities.filter { favoriteIDs.contains($0.id) }.sorted { $0.date < $1.date }
    }

    var joinSuccessActivity: Activity? {
        guard let id = joinSuccessActivityID else { return nil }
        return activity(id: id)
    }

    func isFavorite(_ id: Activity.ID) -> Bool { favoriteIDs.contains(id) }
    func isJoined(_ id: Activity.ID) -> Bool { joinedIDs.contains(id) }
    func isWaitlisted(_ id: Activity.ID) -> Bool { waitlistIDs.contains(id) }

    /// 与已参加 / 我发起的未结束活动时间重叠的场次（不含候选本身）
    func scheduleConflicts(with candidate: Activity) -> [Activity] {
        activities
            .filter {
                !$0.isLifecycleEnded
                    && (joinedIDs.contains($0.id) || $0.hostName == currentUserName)
                    && candidate.scheduleOverlaps($0)
            }
            .sorted { $0.date < $1.date }
    }

    func isHost(_ activity: Activity) -> Bool {
        activity.hostName == currentUserName
    }

    func isHost(id: Activity.ID) -> Bool {
        guard let activity = activity(id: id) else { return false }
        return isHost(activity)
    }

    func hostedCount(for hostName: String) -> Int {
        activities.count { $0.hostName == hostName }
    }

    /// 改名后同步发起/参加名单中的昵称
    func migrateUserName(from oldName: String, to newName: String) {
        guard !oldName.isEmpty, !newName.isEmpty, oldName != newName else { return }
        var changed = false
        for index in activities.indices {
            if activities[index].hostName == oldName {
                activities[index].hostName = newName
                changed = true
            }
            if let participantIndex = activities[index].participantNames.firstIndex(of: oldName) {
                activities[index].participantNames[participantIndex] = newName
                changed = true
            }
        }
        if changed { persist() }
    }

    func refreshDistancesFromLocation() {
        var next = activities
        var changed = false
        for index in next.indices {
            guard let lat = next[index].latitude,
                  let lon = next[index].longitude,
                  let km = locationService.distanceKM(to: lat, longitude: lon)
            else { continue }
            if abs(next[index].distanceKM - km) > 0.05 {
                next[index].distanceKM = km
                changed = true
            }
        }
        if changed {
            activities = next
            invalidateRecommendationShelvesCache()
        }
    }

    func invalidateRecommendationShelvesCache() {
        recommendationShelvesCacheKey = nil
        cachedRecommendationShelves = []
    }
    func activity(id: Activity.ID) -> Activity? {
        activities.first { $0.id == id }
    }

    func activity(matchingTitle title: String) -> Activity? {
        activities.first { $0.title == title }
    }

    func activities(matchingTitles titles: [String]) -> [Activity] {
        titles.compactMap { activity(matchingTitle: $0) }
    }

    func activity(relatedTo post: CommunityPost) -> Activity? {
        if let id = post.relatedActivityID {
            return activity(id: id)
        }
        if let title = post.relatedActivityTitle {
            return activity(matchingTitle: title)
        }
        return nil
    }

    func flash(_ message: String) {
        toastMessage = message
    }

    func flashLight(_ message: String) {
        lightFeedbackMessage = message
    }

    func bumpCalendarSync() {
        calendarSyncRevision += 1
    }

    func persist() {
        let snapshot = ActivitiesSnapshot(
            activities: activities,
            joinedIDs: Array(joinedIDs),
            favoriteIDs: Array(favoriteIDs),
            waitlistIDs: Array(waitlistIDs),
            waitlistSpotNotifiedIDs: Array(waitlistSpotNotifiedIDs),
            participationProgress: participationProgress,
            feedbackTagCounts: feedbackTagCounts
        )
        let previousTask = persistTask
        let generation = persistenceGeneration
        persistTask = MainActorPersistence.chained(after: previousTask) {
            do {
                try await self.repository.replaceAsync(with: snapshot, generation: generation)
            } catch {
                assertionFailure("Activities persist failed: \(error)")
                PersistenceWriteFailureReporter.record(domainKey: "activities", error: error)
                self.flash("保存失败，请稍后重试")
            }
        }
    }

    func reloadFromRepository() async {
        guard let snapshot = try? await repository.loadAsync() else { return }
        persistenceGeneration = repository.currentPersistenceGeneration()
        activities = snapshot.activities
        joinedIDs = Set(snapshot.joinedIDs)
        favoriteIDs = Set(snapshot.favoriteIDs)
        waitlistIDs = Set(snapshot.waitlistIDs)
        waitlistSpotNotifiedIDs = Set(snapshot.waitlistSpotNotifiedIDs)
        participationProgress = snapshot.participationProgress
        feedbackTagCounts = snapshot.feedbackTagCounts
    }

    func discardPendingPersistence() async {
        persistTask?.cancel()
        _ = await persistTask?.result
        persistTask = nil
        repository.invalidatePendingWrites()
        persistenceGeneration = repository.currentPersistenceGeneration()
    }

    func processWaitlistSpotAvailability(for activityID: Activity.ID) {
        guard let activity = activity(id: activityID) else { return }
        switch participation.evaluateWaitlistSpot.execute(
            activityID: activityID,
            activity: activity,
            isOnWaitlist: waitlistIDs.contains(activityID),
            waitlistSpotNotifiedIDs: &waitlistSpotNotifiedIDs
        ) {
        case .none:
            break
        case .revoke(let id):
            NotificationService.cancelWaitlistSpotNotification(activityID: id)
            persist()
        case .notify(let id, let title):
            NotificationService.scheduleWaitlistSpotAvailable(activityID: id, title: title)
            flash(ActivityFeedbackCopy.waitlistSpotOpened(title: title))
            persist()
        }
    }

    func clearWaitlistPromotionState(for activityID: Activity.ID) {
        waitlistIDs.remove(activityID)
        waitlistSpotNotifiedIDs.remove(activityID)
        NotificationService.cancelWaitlistSpotNotification(activityID: activityID)
    }
}

