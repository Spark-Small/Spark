//
//  ActivitiesModel+Participation.swift
//  坐标系
//

import CoordinateDomain
import Foundation
import Observation
import CoordinateModels

extension ActivitiesModel {
    func toggleFavorite(_ id: Activity.ID) {
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
            flashLight(ActivityFeedbackCopy.unfavorited)
        } else {
            favoriteIDs.insert(id)
            flashLight(ActivityFeedbackCopy.favorited)
            if let activity = activity(id: id) {
                engagementStore.record(.favorited, for: activity)
            }
        }
        persist()
    }

    @discardableResult
    func toggleJoin(_ id: Activity.ID) -> Bool {
        if joinedIDs.contains(id) {
            switch participation.leave.execute(
                activityID: id,
                activities: &activities,
                joinedIDs: &joinedIDs,
                currentUserName: currentUserName
            ) {
            case .success:
                NotificationService.cancelActivityReminder(activityID: id)
                NotificationService.cancelActivityRecapReminder(activityID: id)
                walletPassStore.void(relatedID: id)
                if let order = ActivityPaymentStore.paidOrder(for: id) {
                    walletPassStore.void(relatedID: order.id)
                }
                removeParticipationProgress(for: id)
                persist()
                processWaitlistSpotAvailability(for: id)
                flashLight(ActivityFeedbackCopy.unjoined)
                return false
            case .failure:
                flash(ActivityFeedbackCopy.joinFailed)
                return false
            }
        }

        switch participation.join.execute(
            activityID: id,
            activities: &activities,
            joinedIDs: &joinedIDs,
            waitlistIDs: &waitlistIDs,
            waitlistSpotNotifiedIDs: &waitlistSpotNotifiedIDs,
            currentUserName: currentUserName
        ) {
        case .success:
            joinSuccessActivityID = id
            ensureParticipationProgress(for: id)
            if let activity = activity(id: id) {
                engagementStore.record(.joined, for: activity)
                NotificationService.scheduleActivityReminder(
                    activityID: id,
                    title: activity.title,
                    at: activity.date
                )
                NotificationService.scheduleActivityRecapReminder(
                    activityID: id,
                    title: activity.title,
                    activityStart: activity.date
                )
            }
            clearWaitlistPromotionState(for: id)
            persist()
            return true
        case .failure(.alreadyFull):
            flashLight(ActivityCardStatus.fullWaitlistAnnounce)
            return false
        case .failure(.lifecycleEnded):
            flash(ActivityDetailCopy.activityEnded)
            return false
        case .failure(.activityNotFound):
            flash(ActivityFeedbackCopy.activityUnavailable)
            return false
        case .failure(.alreadyJoined):
            flashLight(ActivityCardStatus.joined)
            return false
        case .failure:
            flash(ActivityFeedbackCopy.joinFailed)
            return false
        }
    }

    @discardableResult
    func toggleWaitlist(_ id: Activity.ID) -> Bool {
        switch participation.toggleWaitlist.execute(
            activityID: id,
            activities: activities,
            joinedIDs: joinedIDs,
            waitlistIDs: &waitlistIDs,
            waitlistSpotNotifiedIDs: &waitlistSpotNotifiedIDs
        ) {
        case .joined:
            flashLight(ActivityFeedbackCopy.waitlistJoined)
            persist()
            processWaitlistSpotAvailability(for: id)
            return true
        case .left:
            NotificationService.cancelWaitlistSpotNotification(activityID: id)
            flashLight(ActivityFeedbackCopy.waitlistLeft)
            persist()
            return false
        case .unnecessary:
            flashLight(ActivityFeedbackCopy.waitlistUnnecessary)
            return false
        case .activityNotFound:
            return false
        }
    }

    /// 满员活动空出名额时，候补用户可一键转正（免费或已支付）
    @discardableResult
    func promoteFromWaitlist(_ id: Activity.ID) -> Bool {
        switch participation.promoteFromWaitlist.execute(
            activityID: id,
            activities: &activities,
            joinedIDs: &joinedIDs,
            waitlistIDs: &waitlistIDs,
            waitlistSpotNotifiedIDs: &waitlistSpotNotifiedIDs,
            currentUserName: currentUserName,
            hasPaid: ActivityPaymentStore.hasPaid(for: id)
        ) {
        case .success:
            joinSuccessActivityID = id
            ensureParticipationProgress(for: id)
            if let activity = activity(id: id) {
                engagementStore.record(.joined, for: activity)
                NotificationService.scheduleActivityReminder(
                    activityID: id,
                    title: activity.title,
                    at: activity.date
                )
                NotificationService.scheduleActivityRecapReminder(
                    activityID: id,
                    title: activity.title,
                    activityStart: activity.date
                )
            }
            clearWaitlistPromotionState(for: id)
            persist()
            flashLight(ActivityFeedbackCopy.waitlistPromoted)
            return true
        case .failure(.paymentRequired):
            flash(ActivityFeedbackCopy.waitlistPaymentRequired)
            return false
        case .failure:
            return false
        }
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
}
