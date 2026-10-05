//
//  ActivitiesModel.swift
//  坐标系
//
//  活动目录 / 报名快照门面。Sheet / toast 在 `presentation`。
//

import CoordinateDomain
import Foundation
import Observation

@MainActor
@Observable
final class ActivitiesModel {
    var selectedCategory: ActivityCategory = .forYou
    /// `true` 时发现区展示「最近看过」（不改 `selectedCategory`，以便返回分类）。
    var isBrowsingRecents = false
    var quickFilters: Set<ActivityQuickFilter> = []
    /// 浏览会话「附近」半径（km）。仅与 `.nearby` 联用；不写入全局 RecommendationConfig。
    var nearbyFilterRadiusKM: Double? = nil
    var activities: [Activity]
    var favoriteIDs: Set<UUID>
    var joinedIDs: Set<UUID>
    var waitlistIDs: Set<UUID>
    var currentUserName: String
    var currentUserID: UUID
    var waitlistSpotNotifiedIDs: Set<UUID>
    var participationProgress: [ActivityParticipationProgress]
    /// 日历写入不经过本 Model，用 revision 驱动待办 / 行程 UI 同步。
    var calendarSyncRevision = 0
    var feedbackTagCounts: [String: [String: Int]]

    /// 表现态（compose / 成功 Sheet / toast）
    var presentation = ActivitiesPresentationStore()

    let repository: any ActivitiesRepository
    @ObservationIgnored let engagementStore: ActivityEngagementStore
    @ObservationIgnored let recentBrowseStore: ProfileRecentBrowseStore
    @ObservationIgnored let walletPassStore: WalletPassStore
    @ObservationIgnored let locationService: LocationService
    @ObservationIgnored let participation: ActivitiesParticipationUseCases
    @ObservationIgnored let hosting: ActivitiesHostingUseCases
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
        hosting: ActivitiesHostingUseCases,
        browse: ActivitiesBrowseUseCases,
        recentBrowseStore: ProfileRecentBrowseStore,
        walletPassStore: WalletPassStore,
        locationService: LocationService,
        currentUserName: String? = nil,
        currentUserID: UUID? = nil
    ) {
        self.repository = repository
        self.engagementStore = engagementStore
        self.participation = participation
        self.hosting = hosting
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
        self.currentUserID = currentUserID ?? ParticipantIdentity.currentUserID
        persistenceGeneration = repository.currentPersistenceGeneration()
        refreshDistancesFromLocation()
    }

    var browseSurface: ActivitiesBrowseSurface {
        isBrowsingRecents ? .recents : .category(selectedCategory)
    }

    var browseNavigationTitle: String { browseSurface.title }

    func selectBrowseCategory(_ category: ActivityCategory) {
        isBrowsingRecents = false
        selectedCategory = category
    }

    func selectBrowseRecents() {
        isBrowsingRecents = true
    }

    /// 退出「最近看过」，回到进入前的分类（`selectedCategory` 未改）。
    func exitBrowseRecents() {
        isBrowsingRecents = false
    }

    var joinedActivities: [Activity] {
        activities.filter { joinedIDs.contains($0.id) }.sorted { $0.date < $1.date }
    }

    var waitlistedActivities: [Activity] {
        activities.filter { waitlistIDs.contains($0.id) }.sorted { $0.date < $1.date }
    }

    var hostedActivities: [Activity] {
        activities
            .filter { isHost($0) }
            .sorted { $0.date < $1.date }
    }

    /// 邀约 / 群聊可选：已参加 + 我发起的，未结束
    var inviteableActivities: [Activity] {
        activities
            .filter {
                !$0.isLifecycleEnded
                    && (joinedIDs.contains($0.id) || isHost($0))
            }
            .sorted { $0.date < $1.date }
    }

    var favoriteActivities: [Activity] {
        activities.filter { favoriteIDs.contains($0.id) }.sorted { $0.date < $1.date }
    }

    var joinSuccessActivity: Activity? {
        guard let id = presentation.joinSuccessActivityID else { return nil }
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
                    && (joinedIDs.contains($0.id) || isHost($0))
                    && candidate.scheduleOverlaps($0)
            }
            .sorted { $0.date < $1.date }
    }

    func isHost(_ activity: Activity) -> Bool {
        ActivityHostAuthorization.isHost(
            activity,
            hostName: currentUserName,
            hostUserID: currentUserID
        )
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
        guard !oldName.isEmpty, !newName.isEmpty,
              oldName.caseInsensitiveCompare(newName) != .orderedSame
        else { return }
        var changed = false
        for index in activities.indices {
            if activities[index].hostName.caseInsensitiveCompare(oldName) == .orderedSame {
                activities[index].hostName = newName
                changed = true
            }
            for participantIndex in activities[index].participantNames.indices
            where activities[index].participantNames[participantIndex]
                .caseInsensitiveCompare(oldName) == .orderedSame
            {
                activities[index].participantNames[participantIndex] = newName
                changed = true
            }
        }
        if currentUserName.caseInsensitiveCompare(oldName) == .orderedSame {
            currentUserName = newName
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
        presentation.flash(message)
    }

    func flashLight(_ message: String) {
        presentation.flashLight(message)
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
        do {
            let snapshot = try await repository.loadAsync()
            persistenceGeneration = repository.currentPersistenceGeneration()
            activities = snapshot.activities
            joinedIDs = Set(snapshot.joinedIDs)
            favoriteIDs = Set(snapshot.favoriteIDs)
            waitlistIDs = Set(snapshot.waitlistIDs)
            waitlistSpotNotifiedIDs = Set(snapshot.waitlistSpotNotifiedIDs)
            participationProgress = snapshot.participationProgress
            feedbackTagCounts = snapshot.feedbackTagCounts
        } catch {
            flash(ActivityBrowseCopy.reloadFailed)
        }
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
