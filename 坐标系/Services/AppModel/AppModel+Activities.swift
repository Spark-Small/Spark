//
//  AppModel+Activities.swift
//  坐标系
//

import Foundation
import CoordinateDomain
import CoordinateModels

extension AppModel {
    @discardableResult
    func toggleJoinActivity(_ id: Activity.ID) -> Bool {
        let wasHost = activities.isHost(id: id)
        let joined = activities.toggleJoin(id)
        syncOrchestrator.handle(joined ? .activityJoined(id) : .activityLeft(id, wasHost: wasHost))
        return joined
    }

    func completeActivityPublish(_ id: Activity.ID) {
        syncOrchestrator.handle(.activityPublished(id))
    }

    func beginEditActivity(_ id: Activity.ID) {
        selectedTab = .activities
        activities.beginEdit(id)
    }

    func beginComposeActivity() {
        selectedTab = .activities
        activities.editingActivityID = nil
        activities.isComposing = true
    }

    @discardableResult
    func cancelActivityRegistration(_ id: Activity.ID, refundIfPaid: Bool = false) -> Bool {
        let isHost = activities.isHost(id: id)
        let wasJoined = activities.isJoined(id)
        if refundIfPaid, let order = ActivityPaymentStore.paidOrder(for: id) {
            _ = refundFlowService.submitExpeditedActivityRefund(
                order: order,
                reason: "取消报名",
                detail: "用户取消参加活动，系统自动退款。"
            )
        }
        if wasJoined {
            activities.toggleJoin(id)
        }
        syncOrchestrator.handle(.activityLeft(id, wasHost: isHost))
        return wasJoined
    }

    func cancelHostedActivity(_ id: Activity.ID) {
        guard activities.isHost(id: id), activities.activity(id: id) != nil else { return }
        syncOrchestrator.handle(.activityCancelled(id))
    }

    @discardableResult
    func promoteWaitlistedActivity(_ id: Activity.ID) -> Bool {
        let promoted = activities.promoteFromWaitlist(id)
        if promoted {
            syncOrchestrator.handle(.activityJoined(id))
        }
        return promoted
    }

    @discardableResult
    func quickJoinActivity(_ activity: Activity, openDetail: @escaping () -> Void) -> Bool {
        guard requireIdentityAccess() else { return false }
        if activities.isWaitlisted(activity.id), !activity.isFull, !activity.isLifecycleEnded {
            if activity.requiresInAppPayment {
                if ActivityPaymentStore.hasPaid(for: activity.id) {
                    return promoteWaitlistedActivity(activity.id)
                }
                openDetail()
                return false
            }
            return promoteWaitlistedActivity(activity.id)
        }
        if activity.isFull {
            if activities.isWaitlisted(activity.id) {
                _ = activities.toggleWaitlist(activity.id)
                return false
            }
            if activity.requiresInAppPayment {
                openDetail()
                return false
            }
            return activities.toggleWaitlist(activity.id)
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

    @discardableResult
    func prepareActivityGroupChatRoute(for activity: Activity) -> PeerChatRoute? {
        guard let convo = startActivityGroupChat(for: activity) else { return nil }
        return PeerChatRoute(
            conversationID: convo.id,
            chatContext: .activityGroup(activityID: activity.id)
        )
    }

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
            walletPassStore.refreshActivityPass(activity: activity)
        }
        syncOrchestrator.handle(.activityEdited(id))
    }

    @discardableResult
    func prepareClubGroupChatRoute(for circle: InterestCircle) -> PeerChatRoute? {
        guard let convo = messages.startCircleChat(for: circle, memberName: user.name) else {
            return nil
        }
        return PeerChatRoute(
            conversationID: convo.id,
            chatContext: .clubGroup(circleID: circle.id)
        )
    }

    func openClubGroupChatInStack(
        for circle: InterestCircle,
        navigation: TabNavigationState?
    ) {
        guard let route = prepareClubGroupChatRoute(for: circle) else { return }
        if let navigation {
            navigation.openClubGroupChat(for: circle, route: route)
        } else {
            openMessages(conversationID: route.conversationID)
        }
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
}
