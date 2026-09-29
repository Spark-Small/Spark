//
//  AppDomainServices.swift
//  坐标系
//

import Foundation
import CoordinateModels

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
        ActivityPaymentStore.walletStore = app.walletStore
        ActivityPaymentStore.walletPassStore = app.walletPassStore
        ActivityRecommender.engagementStore = app.activityEngagementStore
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
        let notes = ActivityDetailBlueprint.make(for: activity).refundNotes
        app.refundFlowService.submitSystemActivityRefunds(
            for: activityID,
            activityTitle: activity.title,
            refundNotes: notes
        )
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
        var next = user
        next.id = LocalUserIdentity.current
        app.user = next
        app.activities.currentUserName = next.name
        app.community.currentUserName = next.name
        app.buddies.currentUserName = next.name
        if previousName != next.name {
            app.activities.migrateUserName(from: previousName, to: next.name)
        }
        app.refreshInterestContext(next.interests)
    }

    func applyOnboarding(interests: [String], app: AppModel) {
        if app.user.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            app.user.name = "坐标系用户"
        }
        if app.user.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            app.user.city = "上海"
        }
        app.user.id = LocalUserIdentity.current
        app.user.interests = interests
        app.activities.currentUserName = app.user.name
        app.community.currentUserName = app.user.name
        app.buddies.currentUserName = app.user.name
        app.refreshInterestContext(interests)
        app.hasCompletedWelcomeBootstrap = true
    }

    func apply(snapshot: ProfileSnapshot, app: AppModel) {
        var nextUser = snapshot.user
        nextUser.id = LocalUserIdentity.current
        app.user = nextUser
        app.hasCompletedWelcomeBootstrap = snapshot.hasCompletedOnboarding
        app.blockedUserNames = Set(snapshot.blockedUserNames)
        app.moderationTickets = snapshot.moderationTickets.sorted { $0.createdAt > $1.createdAt }
        app.activities.currentUserName = nextUser.name
        app.community.currentUserName = nextUser.name
        app.buddies.currentUserName = nextUser.name
        app.buddies.blockedUserNames = app.blockedUserNames
        app.community.blockedUserNames = app.blockedUserNames
        app.refreshInterestContext(nextUser.interests)
    }
}

@MainActor
struct TrustBehaviorSyncService {
    func handle(_ event: AppDomainEvent, app: AppModel) {
        let actor = app.user.name
        switch event {
        case .activityJoined:
            app.trustService.record(.activityJoined, domain: .activity, actorKey: actor)
        case .activityLeft:
            app.trustService.record(.activityLeft, domain: .activity, actorKey: actor)
        case .activityPublished:
            app.trustService.record(.activityHosted, domain: .activity, actorKey: actor)
        case .activityCancelled:
            app.trustService.record(.activityHostCancelled, domain: .activity, actorKey: actor)
        case .profileUpdated(_, let user):
            app.trustService.record(
                .profileCompletionChanged,
                domain: .account,
                actorKey: user.name,
                value: ProfileCompletion.ratio(for: user)
            )
        case .onboardingCompleted:
            app.trustService.record(.onboardingCompleted, domain: .account, actorKey: actor)
        case .userBlocked(let name):
            app.trustService.record(
                .blocked,
                domain: .social,
                actorKey: actor,
                subjectKey: name
            )
        case .userUnblocked(let name):
            app.trustService.record(
                .unblocked,
                domain: .social,
                actorKey: actor,
                subjectKey: name
            )
        case .moderationTicketAdded(let ticket) where ticket.targetKind == .person:
            app.trustService.record(
                .personReported,
                domain: .moderation,
                actorKey: actor,
                subjectKey: ticket.postTitle
            )
        default:
            break
        }
    }
}

@MainActor
struct AppSafetySyncService {
    func blockUser(_ name: String, app: AppModel) {
        app.blockedUserNames.insert(name)
        app.buddies.blockedUserNames = app.blockedUserNames
        app.community.blockedUserNames = app.blockedUserNames
        app.messages.deleteDirectChat(with: name)
        app.buddies.purgeSocialLinks(with: name)
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
