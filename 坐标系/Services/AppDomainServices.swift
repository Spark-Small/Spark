//
//  AppDomainServices.swift
//  坐标系
//

import Foundation

protocol ActivitiesDerivedStateProviding {
    var derivedJoinedIDs: Set<UUID> { get }
    var derivedJoinedCount: Int { get }
    var derivedHostedCount: Int { get }
}

protocol MessagesDerivedStateProviding {
    var derivedDirectConversationNames: Set<String> { get }
}

protocol BuddyRecordsDerivedStateProviding {
    var derivedInviteNicknames: Set<String> { get }
    var derivedBookingNicknames: Set<String> { get }
}

@MainActor
struct AppDerivedStateService {
    func refreshRecommendations(app: AppModel) {
        ActivityRecommender.userInterests = app.user.interests.isEmpty
            ? SampleData.currentUserInterests
            : app.user.interests
        ActivityRecommender.currentUserName = app.user.name
        ActivityRecommender.joinedIDs = app.activities.derivedJoinedIDs
        ActivityRecommender.friendNames = derivedBuddyNames(
            messages: app.messages,
            buddies: app.buddies
        )
    }

    func refreshProfileStats(app: AppModel) {
        let joinedCount = app.activities.derivedJoinedCount
        let hostedCount = app.activities.derivedHostedCount
        let buddyCount = derivedBuddyNames(messages: app.messages, buddies: app.buddies).count

        guard app.user.joinedCount != joinedCount
            || app.user.hostedCount != hostedCount
            || app.user.buddyCount != buddyCount
        else { return }

        app.user.joinedCount = joinedCount
        app.user.hostedCount = hostedCount
        app.user.buddyCount = buddyCount
        app.persistProfile()
    }

    func refreshAll(app: AppModel) {
        refreshRecommendations(app: app)
        refreshProfileStats(app: app)
    }

    private func derivedBuddyNames(
        messages: any MessagesDerivedStateProviding,
        buddies: any BuddyRecordsDerivedStateProviding
    ) -> Set<String> {
        messages.derivedDirectConversationNames
            .union(buddies.derivedInviteNicknames)
            .union(buddies.derivedBookingNicknames)
    }
}

@MainActor
struct ActivityConversationSyncService {
    func handleJoin(activityID: Activity.ID, app: AppModel) {
        guard let activity = app.activities.activity(id: activityID) else { return }
        let role: GroupChatJoinRole = app.activities.isHost(activity) ? .host : .participant
        _ = app.messages.startGroupChat(
            for: activity,
            role: role,
            memberName: app.user.name,
            announceMembership: role == .participant
        )
    }

    func handleLeave(activityID: Activity.ID, wasHost: Bool, app: AppModel) {
        guard !wasHost else { return }
        app.messages.leaveGroupChat(
            activityID: activityID,
            leaverName: app.user.name,
            currentUserIsOwner: false
        )
    }

    func handlePublish(activityID: Activity.ID, app: AppModel) {
        guard let activity = app.activities.activity(id: activityID) else { return }
        _ = app.messages.startGroupChat(
            for: activity,
            role: .host,
            memberName: app.user.name,
            announceMembership: false
        )
    }

    func handleCancel(activityID: Activity.ID, app: AppModel) {
        guard let activity = app.activities.activity(id: activityID) else { return }
        ActivityPaymentStore.refundAllPaidOrders(for: activityID)
        app.messages.announceActivityCancelled(activity: activity)
        app.activities.cancelActivity(activityID)
    }

    func syncMetadata(activityID: Activity.ID, app: AppModel) {
        guard let activity = app.activities.activity(id: activityID) else { return }
        app.messages.syncGroupMetadata(for: activity)
    }
}

@MainActor
struct AppProfileSyncService {
    func apply(user: AppUser, previousName: String, app: AppModel) {
        app.user = user
        app.activities.currentUserName = user.name
        app.community.currentUserName = user.name
        if previousName != user.name {
            app.activities.migrateUserName(from: previousName, to: user.name)
        }
        app.refreshInterestContext(user.interests)
    }

    func applyOnboarding(interests: [String], app: AppModel) {
        if app.user.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            app.user.name = "坐标系用户"
        }
        if app.user.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            app.user.city = "上海"
        }
        app.user.interests = interests
        app.activities.currentUserName = app.user.name
        app.community.currentUserName = app.user.name
        app.refreshInterestContext(interests)
        app.hasCompletedOnboarding = true
    }

    func apply(snapshot: ProfileSnapshot, app: AppModel) {
        app.user = snapshot.user
        app.hasCompletedOnboarding = snapshot.hasCompletedOnboarding
        app.blockedUserNames = Set(snapshot.blockedUserNames)
        app.moderationTickets = snapshot.moderationTickets.sorted { $0.createdAt > $1.createdAt }
        app.activities.currentUserName = snapshot.user.name
        app.community.currentUserName = snapshot.user.name
        app.buddies.blockedUserNames = app.blockedUserNames
        app.community.blockedUserNames = app.blockedUserNames
        app.refreshInterestContext(snapshot.user.interests)
    }
}

@MainActor
struct AppSafetySyncService {
    func blockUser(_ name: String, app: AppModel) {
        app.blockedUserNames.insert(name)
        app.buddies.blockedUserNames = app.blockedUserNames
        app.community.blockedUserNames = app.blockedUserNames
        app.messages.deleteDirectChat(with: name)
    }

    func unblockUser(_ name: String, app: AppModel) {
        app.blockedUserNames.remove(name)
        app.buddies.blockedUserNames = app.blockedUserNames
        app.community.blockedUserNames = app.blockedUserNames
    }

    func addModerationTicket(_ ticket: ModerationTicket, app: AppModel) {
        app.moderationTickets.insert(ticket, at: 0)
    }
}

extension ActivitiesModel: ActivitiesDerivedStateProviding {
    var derivedJoinedIDs: Set<UUID> { joinedIDs }
    var derivedJoinedCount: Int { joinedActivities.count }
    var derivedHostedCount: Int { hostedActivities.count }
}

extension MessagesModel: MessagesDerivedStateProviding {
    var derivedDirectConversationNames: Set<String> {
        Set(
            conversations
                .filter { $0.kind == .direct }
                .map(\.title)
        )
    }
}

extension BuddiesModel: BuddyRecordsDerivedStateProviding {
    var derivedInviteNicknames: Set<String> { Set(inviteRecords.map(\.nickname)) }
    var derivedBookingNicknames: Set<String> { Set(bookingRecords.map(\.companionNickname)) }
}
