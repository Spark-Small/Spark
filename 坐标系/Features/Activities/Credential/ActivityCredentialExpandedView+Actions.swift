//
//  ActivityCredentialExpandedView+Actions.swift
//  坐标系
//
//  行程更多菜单：取消 / 退款 / 补发 / 分享 / 举报。
//

import SwiftUI
import CoordinateDomain
import CoordinateModels

extension ActivityCredentialExpandedView {

    var shouldOfferReissue: Bool {
        guard let activity, relatedPass == nil || relatedPass?.voided == true else { return false }
        return activities.isJoined(activity.id) || isHost
    }

    @ViewBuilder
    func credentialMoreMenu(for activity: Activity) -> some View {
        Button {
            presentMementoShare(for: activity)
        } label: {
            Label(ActivityJourneyCopy.shareMementoTicket, systemImage: "photo.on.rectangle.angled")
        }

        Button {
            mementoShareItems = [shareText(for: activity)]
            showMementoShareSheet = true
        } label: {
            Label(ActivityCardStatus.shareActivity, systemImage: "text.quote")
        }

        if isHost {
            Button(ActivityDetailCopy.hostManageCancelActivity, systemImage: "xmark.circle", role: .destructive) {
                showCancelHostAlert = true
            }
        } else if activities.isJoined(activity.id) {
            if !activity.isLifecycleEnded {
                Button(ActivityDetailCopy.cancelRegistration, systemImage: "xmark.circle", role: .destructive) {
                    requestCancelRegistration(activity)
                }
            }
        }

        if shouldOfferReissue {
            Button(ActivityDetailCopy.credentialReissueAction, systemImage: "ticket") {
                reissue(activity)
            }
        }

        Divider()

        Button(ActivityDetailCopy.reportAction, systemImage: "exclamationmark.bubble", role: .destructive) {
            showReportSheet = true
        }
    }

    func requestCancelRegistration(_ activity: Activity) {
        if ActivityPaymentStore.hasPaid(for: activity.id) {
            cancelRefundActivityID = activity.id
        } else {
            cancelUnpaidActivityID = activity.id
        }
    }

    @discardableResult
    func submitCancelAndRefund(order: ActivityOrder, reason: String, detail: String) -> Bool {
        let activity = activities.activity(id: order.activityID)
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
            return true
        case .failure(let error):
            actionIssueMessage = error.localizedDescription
            return false
        }
    }

    func reissue(_ activity: Activity) {
        if let order = ActivityPaymentStore.paidOrder(for: activity.id) {
            _ = passStore.issueActivityTicket(order: order, activity: activity)
        } else {
            _ = passStore.issueActivityAttendanceTicket(for: activity)
        }
    }

    func presentMementoShare(for activity: Activity) {
        let isVoided = relatedPass?.voided == true
        let participates = activities.isJoined(activity.id) || isHost
        let progress = activities.participationRecord(for: activity.id)
        let phase = ActivityJourneyPresentation.phase(
            for: activity,
            progress: progress,
            participatesInJourney: participates
        )
        let model = ActivityJourneyCredentialPresentation.shareModel(
            for: activity,
            phase: phase,
            voided: isVoided,
            userID: app.user.id,
            participantName: app.user.name,
            participantUIDDisplay: app.user.publicUIDDisplay,
            barcodeMessage: barcodeMessage(for: activity, voided: isVoided)
        )
        let caption = ActivityJourneyCredentialPresentation.shareCaption(for: activity)
        var items: [Any] = [caption]
        if let image = ActivityCredentialShareRenderer.renderMementoCard(
            model: model,
            shareCaption: caption
        ) {
            items.insert(image, at: 0)
        }
        mementoShareItems = items
        showMementoShareSheet = true
    }

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
}
