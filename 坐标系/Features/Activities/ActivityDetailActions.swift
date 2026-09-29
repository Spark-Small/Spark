//
//  ActivityDetailActions.swift
//  坐标系
//
//  活动详情页动作编排（与 `ActivityDetailView` 共享状态）。
//

import SwiftUI
import CoordinateDomain
import CoordinateModels

extension ActivityDetailView {
    func shareText(for activity: Activity) -> String {
        "\(activity.title)\n\(Formatters.activityEventTime(from: activity.date))\n\(activity.location)"
    }

    func submitReport(reason: String, detail: String, evidenceCount: Int) {
        guard let activity else { return }
        var parts = [reason, detail]
        if evidenceCount > 0 {
            parts.append("附件 \(evidenceCount) 张")
        }
        app.addModerationTicket(
            postID: activity.id,
            title: activity.title,
            reason: parts.joined(separator: " · "),
            targetKind: .activity
        )
        reportMessage = ActivityDetailCopy.reportReceivedMessage
    }

    func openGroupChat(for activity: Activity) {
        app.activities.markActivityGroupOpened(activity.id)
        guard let route = app.prepareActivityGroupChatRoute(for: activity) else { return }
        if let navigation {
            navigation.openActivityGroupChat(for: activity, route: route)
        } else {
            activityContactRoute = .chat(route)
        }
    }

    func askHost(about activity: Activity) {
        openActivityChat(with: activity.hostName, about: activity)
    }

    func openActivityChat(with name: String, about activity: Activity) {
        let context: ConversationChatContext = name == activity.hostName
            ? .activityHost(activityID: activity.id)
            : .activityMember(activityID: activity.id)
        activityContactRoute = app.openPeerContact(with: name, context: context)
    }

    func openRecapCompose(for activity: Activity) {
        community.pendingRelatedActivityTitle = activity.title
        community.pendingRelatedActivityID = activity.id
        community.pendingComposeBody = "「\(activity.title)」复盘"
        showRecapCompose = true
    }

    func requestCancelRegistration(_ activity: Activity) {
        if ActivityPaymentStore.hasPaid(for: activity.id) {
            cancelRefundActivityID = activity.id
        } else {
            cancelUnpaidActivityID = activity.id
        }
    }

    func completeJoin(for activity: Activity, note: String?) {
        guard app.requireIdentityAccess() else { return }
        guard let live = model.activity(id: activity.id) else { return }

        if live.isFull || live.isLifecycleEnded {
            refundPaidOrderIfNeeded(for: live.id)
            joinIssueMessage = ActivityDetailCopy.joinFailedFullAfterPayMessage
            return
        }

        if let note, !note.isEmpty {
            _ = app.messages.sendFriendRequest(
                to: live.hostName,
                message: "\(ActivityDetailCopy.joinNotePrefix)\(note)"
            )
        }

        let joined: Bool
        if model.isWaitlisted(live.id), !live.isFull, !live.isLifecycleEnded {
            joined = app.promoteWaitlistedActivity(live.id)
        } else {
            joined = app.toggleJoinActivity(live.id)
        }
        if !joined {
            refundPaidOrderIfNeeded(for: live.id)
            joinIssueMessage = ActivityDetailCopy.joinFailedFullAfterPayMessage
        } else {
            _ = passStore.issueActivityAttendanceTicket(for: live)
        }
    }

    func refundPaidOrderIfNeeded(for activityID: Activity.ID) {
        guard let order = ActivityPaymentStore.paidOrder(for: activityID) else { return }
        _ = refunds.submitExpeditedActivityRefund(
            order: order,
            reason: "报名失败",
            detail: "支付成功但未能完成报名，系统自动退款。"
        )
        ordersRevision += 1
    }

    @discardableResult
    func submitCancelAndRefund(order: ActivityOrder, reason: String, detail: String) -> Bool {
        let activity = model.activity(id: order.activityID)
        let notes = activity.map { ActivityDetailBlueprint.make(for: $0).refundNotes } ?? []
        let result = refunds.submitActivityRefund(
            order: order,
            activity: activity,
            refundNotes: notes,
            reason: reason,
            detail: detail,
            cancelRegistration: true,
            onCancelRegistration: { id in
                app.cancelActivityRegistration(id, refundIfPaid: false)
            }
        )
        switch result {
        case .success(let record):
            presentedRefundRequestID = record.id
            ordersRevision += 1
            return true
        case .failure(let error):
            joinIssueMessage = error.localizedDescription
            return false
        }
    }
}
