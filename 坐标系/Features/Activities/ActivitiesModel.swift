//
//  ActivitiesModel.swift
//  坐标系
//

import Foundation
import Observation

@MainActor
@Observable
final class ActivitiesModel {
    var selectedCategory: ActivityCategory = .all
    var quickFilters: Set<ActivityQuickFilter> = []
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
    private var waitlistSpotNotifiedIDs: Set<UUID>
    private let repository: ActivitiesRepository
    @ObservationIgnored private var persistenceGeneration: Int
    @ObservationIgnored private var persistTask: Task<Void, Never>?
    /// 货架结果缓存：避免每次 body / 返回发现页都整库重排
    @ObservationIgnored private var cachedRecommendationShelves: [ActivityBrowseShelf] = []
    @ObservationIgnored private var recommendationShelvesCacheKey: RecommendationShelvesCacheKey?

    init(currentUserName: String? = nil, repository: ActivitiesRepository? = nil) {
        let resolvedRepository = repository ?? LocalActivitiesRepository()
        self.repository = resolvedRepository
        let snapshot = resolvedRepository.load()
        activities = snapshot.activities
        joinedIDs = Set(snapshot.joinedIDs)
        favoriteIDs = Set(snapshot.favoriteIDs)
        waitlistIDs = Set(snapshot.waitlistIDs)
        waitlistSpotNotifiedIDs = Set(snapshot.waitlistSpotNotifiedIDs)
        self.currentUserName = currentUserName ?? SampleData.currentUser.name
        persistenceGeneration = resolvedRepository.currentPersistenceGeneration()
        refreshDistancesFromLocation()
    }

    /// 默认浏览态：精选 Hero + 目录模块（筛选时隐藏精选）
    var showsBrowseModules: Bool {
        selectedCategory == .all && quickFilters.isEmpty
    }

    private var catalogIndexByID: [UUID: Int] {
        Dictionary(uniqueKeysWithValues: activities.enumerated().map { ($0.element.id, $0.offset) })
    }

    /// 当前可见目录（分类 / 快捷筛选）
    var filtered: [Activity] {
        activities.filter { activity in
            let matchesCategory = selectedCategory == .all || activity.category == selectedCategory
            return matchesCategory && matchesQuickFilters(activity)
        }
    }

    var featured: [Activity] {
        ActivityBrowseFeed.featured(
            from: filtered,
            catalogIndex: catalogIndexByID,
            showsHero: showsBrowseModules
        )
    }

    var showsFeatured: Bool { !featured.isEmpty && showsBrowseModules }

    /// 长列表推荐分区（精选 Hero 以下）。按输入指纹缓存，返回详情后滑动不重算整库。
    var recommendationShelves: [ActivityBrowseShelf] {
        let key = RecommendationShelvesCacheKey(
            category: selectedCategory,
            filters: quickFilters,
            activityRevision: activities.map(\.id),
            joinedIDs: joinedIDs,
            featuredIDs: Set(featured.map(\.id))
        )
        if key == recommendationShelvesCacheKey {
            return cachedRecommendationShelves
        }
        let built = ActivityBrowseShelfBuilder.build(
            catalog: filtered,
            featuredIDs: key.featuredIDs,
            joinedIDs: joinedIDs,
            interests: ActivityRecommender.userInterests,
            catalogIndex: catalogIndexByID
        )
        cachedRecommendationShelves = built
        recommendationShelvesCacheKey = key
        return built
    }

    /// 打开详情即记一次隐式浏览信号，喂给推荐做行为学习（见 ActivityEngagementStore）
    func recordDetailView(_ id: Activity.ID) {
        guard let activity = activity(id: id) else { return }
        ActivityEngagementStore.shared.record(.viewed, for: activity)
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

    func isHost(_ activity: Activity) -> Bool {
        activity.hostName == currentUserName
    }

    func isHost(id: Activity.ID) -> Bool {
        guard let activity = activity(id: id) else { return false }
        return isHost(activity)
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
                  let km = LocationService.shared.distanceKM(to: lat, longitude: lon)
            else { continue }
            if abs(next[index].distanceKM - km) > 0.05 {
                next[index].distanceKM = km
                changed = true
            }
        }
        if changed {
            activities = next
        }
    }

    func activity(id: Activity.ID) -> Activity? {
        activities.first { $0.id == id }
    }

    func activity(matchingTitle title: String) -> Activity? {
        activities.first { $0.title == title }
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

    func clearQuickFilters() {
        quickFilters = []
    }

    func toggleQuickFilter(_ filter: ActivityQuickFilter) {
        if filter.isTimeFilter {
            if quickFilters.contains(filter) {
                quickFilters.remove(filter)
            } else {
                quickFilters = Set(quickFilters.filter { !$0.isTimeFilter } + [filter])
            }
        } else if quickFilters.contains(filter) {
            quickFilters.remove(filter)
        } else {
            quickFilters.insert(filter)
        }
    }

    func toggleFavorite(_ id: Activity.ID) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
            flash(ActivityFeedbackCopy.unfavorited)
        } else {
            favoriteIDs.insert(id)
            flash(ActivityFeedbackCopy.favorited)
            if let activity = activity(id: id) {
                ActivityEngagementStore.shared.record(.favorited, for: activity)
            }
        }
        persist()
    }

    @discardableResult
    func toggleJoin(_ id: Activity.ID) -> Bool {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return false }
        if joinedIDs.contains(id) {
            joinedIDs.remove(id)
            activities[index].joined = max(activities[index].joined - 1, 0)
            activities[index].participantNames.removeAll { $0 == currentUserName }
            NotificationService.cancelActivityReminder(activityID: id)
            WalletPassStore.shared.void(relatedID: id)
            if let order = ActivityPaymentStore.paidOrder(for: id) {
                WalletPassStore.shared.void(relatedID: order.id)
            }
            flash(ActivityFeedbackCopy.unjoined)
            persist()
            processWaitlistSpotAvailability(for: id)
            return false
        } else {
            guard !activities[index].isFull else {
                flash(ActivityCardStatus.fullWaitlistAnnounce)
                return false
            }
            guard !activities[index].isLifecycleEnded else {
                flash(ActivityDetailCopy.activityEnded)
                return false
            }
            joinedIDs.insert(id)
            waitlistIDs.remove(id)
            activities[index].joined = min(activities[index].joined + 1, activities[index].capacity)
            // 勿把 displayParticipants 种子名单写回真实名单（会截断并固化错误人数）
            if !activities[index].participantNames.contains(currentUserName) {
                activities[index].participantNames.append(currentUserName)
            }
            joinSuccessActivityID = id
            ActivityEngagementStore.shared.record(.joined, for: activities[index])
            NotificationService.scheduleActivityReminder(
                activityID: id,
                title: activities[index].title,
                at: activities[index].date
            )
            clearWaitlistPromotionState(for: id)
            persist()
            return true
        }
    }

    @discardableResult
    func toggleWaitlist(_ id: Activity.ID) -> Bool {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return false }
        guard activities[index].isFull,
              !joinedIDs.contains(id),
              !activities[index].isLifecycleEnded
        else {
            flash(ActivityFeedbackCopy.waitlistUnnecessary)
            return false
        }
        if waitlistIDs.contains(id) {
            waitlistIDs.remove(id)
            clearWaitlistPromotionState(for: id)
            flash(ActivityFeedbackCopy.waitlistLeft)
            persist()
            return false
        } else {
            waitlistIDs.insert(id)
            flash(ActivityFeedbackCopy.waitlistJoined)
            persist()
            processWaitlistSpotAvailability(for: id)
            return true
        }
    }

    /// 满员活动空出名额时，候补用户可一键转正（免费或已支付）
    @discardableResult
    func promoteFromWaitlist(_ id: Activity.ID) -> Bool {
        guard waitlistIDs.contains(id),
              let activity = activity(id: id),
              activity.isJoinable
        else { return false }
        if activity.requiresInAppPayment, !ActivityPaymentStore.hasPaid(for: id) {
            return false
        }
        return toggleJoin(id)
    }

    func dismissJoinSuccess() {
        joinSuccessActivityID = nil
    }

    var publishSuccessActivity: Activity? {
        guard let id = publishSuccessActivityID else { return nil }
        return activity(id: id)
    }

    func dismissPublishSuccess() {
        publishSuccessActivityID = nil
    }

    @discardableResult
    func publish(
        title: String,
        category: ActivityCategory,
        location: String,
        date: Date,
        capacity: Int,
        fee: String,
        summary: String,
        tags: [String],
        localCoverName: String?,
        distanceKM: Double = 1.5,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> Activity.ID? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedLocation.isEmpty, !trimmedSummary.isEmpty else { return nil }
        guard category != .all else { return nil }

        var resolvedDistance = distanceKM
        if let latitude, let longitude,
           let km = LocationService.shared.distanceKM(to: latitude, longitude: longitude) {
            resolvedDistance = km
        }

        let id = UUID()
        activities.insert(
            Activity(
                id: id,
                title: trimmedTitle,
                category: category,
                location: trimmedLocation,
                date: date,
                capacity: max(capacity, 2),
                joined: 1,
                hostName: currentUserName,
                summary: trimmedSummary,
                fee: fee.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "免费" : fee,
                tags: tags,
                distanceKM: resolvedDistance,
                localCoverName: localCoverName,
                participantNames: [currentUserName],
                latitude: latitude,
                longitude: longitude
            ),
            at: 0
        )
        joinedIDs.insert(id)
        isComposing = false
        editingActivityID = nil
        publishSuccessActivityID = id
        NotificationService.scheduleActivityReminder(activityID: id, title: trimmedTitle, at: date)
        persist()
        return id
    }

    func beginEdit(_ id: Activity.ID) {
        editingActivityID = id
        isComposing = true
    }

    func update(
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
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return }
        guard activities[index].hostName == currentUserName else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedLocation.isEmpty, !trimmedSummary.isEmpty else { return }
        guard category != .all else { return }

        let joinedCount = activities[index].joined
        activities[index].title = trimmedTitle
        activities[index].category = category
        activities[index].location = trimmedLocation
        activities[index].date = date
        activities[index].capacity = max(capacity, max(joinedCount, 2))
        activities[index].summary = trimmedSummary
        activities[index].fee = fee.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "免费" : fee
        activities[index].tags = tags
        if let localCoverName {
            activities[index].localCoverName = localCoverName
        }
        if latitude != nil { activities[index].latitude = latitude }
        if longitude != nil { activities[index].longitude = longitude }
        if let lat = activities[index].latitude,
           let lon = activities[index].longitude,
           let km = LocationService.shared.distanceKM(to: lat, longitude: lon) {
            activities[index].distanceKM = km
        }
        isComposing = false
        editingActivityID = nil
        if joinedIDs.contains(id) {
            NotificationService.scheduleActivityReminder(activityID: id, title: trimmedTitle, at: date)
        }
        flash(ActivityFeedbackCopy.activityUpdated)
        persist()
    }

    func cancelActivity(_ id: Activity.ID) {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return }
        guard activities[index].hostName == currentUserName else { return }
        if let cover = activities[index].localCoverName {
            CommunityPhotoStore.delete(named: cover)
        }
        ActivityDetailContentStore.delete(for: id)
        joinedIDs.remove(id)
        favoriteIDs.remove(id)
        waitlistIDs.remove(id)
        NotificationService.cancelActivityReminder(activityID: id)
        activities.remove(at: index)
        if joinSuccessActivityID == id {
            joinSuccessActivityID = nil
        }
        if publishSuccessActivityID == id {
            publishSuccessActivityID = nil
        }
        flash(ActivityFeedbackCopy.activityCancelled)
        persist()
    }

    func updateCapacity(_ id: Activity.ID, capacity: Int) {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return }
        guard activities[index].hostName == currentUserName else { return }
        let floor = max(activities[index].joined, 2)
        let next = max(capacity, floor)
        guard activities[index].capacity != next else { return }
        let wasFull = activities[index].isFull
        activities[index].capacity = next
        flash(ActivityFeedbackCopy.capacityUpdated(to: next))
        persist()
        if wasFull, !activities[index].isFull {
            processWaitlistSpotAvailability(for: id)
        }
    }

    func reschedule(_ id: Activity.ID, to date: Date, notifyNote: String?) {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return }
        guard activities[index].hostName == currentUserName else { return }
        guard date > .now else {
            flash(ActivityFeedbackCopy.scheduleNeedsFuture)
            return
        }
        activities[index].date = date
        if joinedIDs.contains(id) {
            NotificationService.scheduleActivityReminder(
                activityID: id,
                title: activities[index].title,
                at: date
            )
        }
        if let notifyNote = notifyNote?.trimmingCharacters(in: .whitespacesAndNewlines),
           !notifyNote.isEmpty {
            var override = ActivityDetailContentStore.override(for: id) ?? ActivityDetailContentOverride()
            let line = "【改期通知】\(Formatters.activityEventTime(from: date)) · \(notifyNote)"
            if let existing = override.hostNote, !existing.isEmpty {
                override.hostNote = existing + "\n" + line
            } else {
                override.hostNote = line
            }
            ActivityDetailContentStore.save(override, for: id)
        }
        flash(ActivityFeedbackCopy.scheduleUpdated)
        persist()
    }

    private func matchesQuickFilters(_ activity: Activity) -> Bool {
        guard !quickFilters.isEmpty else { return true }
        let calendar = Calendar.current

        return quickFilters.allSatisfy { filter in
            switch filter {
            case .today:
                calendar.isDateInToday(activity.date) && !activity.isPast
            case .tomorrow:
                calendar.isDateInTomorrow(activity.date)
            case .nearby:
                activity.isNearby && !activity.isPast
            case .free:
                activity.isFree
            case .available:
                activity.hasAvailableSpots && !activity.isPast
            }
        }
    }

    private func flash(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: .seconds(2))
            if toastMessage == message { toastMessage = nil }
        }
    }

    private func persist() {
        let snapshot = ActivitiesSnapshot(
            activities: activities,
            joinedIDs: Array(joinedIDs),
            favoriteIDs: Array(favoriteIDs),
            waitlistIDs: Array(waitlistIDs),
            waitlistSpotNotifiedIDs: Array(waitlistSpotNotifiedIDs)
        )
        let previousTask = persistTask
        let generation = persistenceGeneration
        persistTask = Task {
            _ = await previousTask?.result
            guard !Task.isCancelled else { return }
            try? await repository.replaceAsync(with: snapshot, generation: generation)
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
    }

    func discardPendingPersistence() async {
        persistTask?.cancel()
        _ = await persistTask?.result
        persistTask = nil
        repository.invalidatePendingWrites()
        persistenceGeneration = repository.currentPersistenceGeneration()
    }

    private func processWaitlistSpotAvailability(for activityID: Activity.ID) {
        guard waitlistIDs.contains(activityID),
              let activity = activity(id: activityID)
        else { return }

        if activity.isFull || activity.isLifecycleEnded {
            waitlistSpotNotifiedIDs.remove(activityID)
            NotificationService.cancelWaitlistSpotNotification(activityID: activityID)
            persist()
            return
        }

        guard !waitlistSpotNotifiedIDs.contains(activityID) else { return }
        waitlistSpotNotifiedIDs.insert(activityID)
        NotificationService.scheduleWaitlistSpotAvailable(
            activityID: activityID,
            title: activity.title
        )
        flash(ActivityFeedbackCopy.waitlistSpotOpened(title: activity.title))
        persist()
    }

    private func clearWaitlistPromotionState(for activityID: Activity.ID) {
        waitlistIDs.remove(activityID)
        waitlistSpotNotifiedIDs.remove(activityID)
        NotificationService.cancelWaitlistSpotNotification(activityID: activityID)
    }
}

/// 货架缓存指纹：分类 / 筛选 / 目录顺序 / 报名 / 精选变化时失效
private struct RecommendationShelvesCacheKey: Equatable {
    var category: ActivityCategory
    var filters: Set<ActivityQuickFilter>
    var activityRevision: [UUID]
    var joinedIDs: Set<UUID>
    var featuredIDs: Set<UUID>
}
