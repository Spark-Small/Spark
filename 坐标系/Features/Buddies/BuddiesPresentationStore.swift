//
//  BuddiesPresentationStore.swift
//  坐标系
//
//  搭子域表现态（Sheet / toast），与快照 / 预约记录分离。
//

import Foundation
import Observation
import CoordinateModels

@MainActor
@Observable
final class BuddiesPresentationStore {
    var inviteTarget: BuddyInviteTarget?
    var bookingPresentation: BuddyBookingPresentation?
    var pendingBookingAcknowledgementID: BuddyBookingRecord.ID?
    var pendingBookingSuccessID: BuddyBookingRecord.ID?
    var pendingInviteSuccessID: BuddyInviteRecord.ID?
    var pendingPaymentBookingID: BuddyBookingRecord.ID?
    /// 接单后待用户主动确认的「待支付」详情 Sheet（不自动打开支付 Sheet）。
    var pendingAwaitingPaymentReviewID: BuddyBookingRecord.ID?
    var pendingSafetyCheckInBookingID: BuddyBookingRecord.ID?
    var toastMessage: String?
    var isComposingClub = false
    var pendingOrgJoin: BuddyOrgJoinTarget?
    var pendingOrgJoinSuccess: BuddyOrgJoinSuccess?
    var pendingOrgInvite: BuddyOrgInviteTarget?
    /// 接受邀约后待打开的关联活动（消费一次即清）
    var pendingOpenActivityAfterInviteID: UUID?

    func flash(_ message: String) {
        toastMessage = message
    }

    /// 取出并清空「接受邀约 → 打开活动」挂起项。
    func consumePendingOpenActivityAfterInvite() -> UUID? {
        defer { pendingOpenActivityAfterInviteID = nil }
        return pendingOpenActivityAfterInviteID
    }

    func dismissBookingAcknowledgement() {
        pendingBookingAcknowledgementID = nil
    }

    func dismissBookingSuccess() {
        pendingBookingSuccessID = nil
    }

    func dismissInviteSuccess() {
        pendingInviteSuccessID = nil
    }

    func dismissAwaitingPaymentReview() {
        pendingAwaitingPaymentReviewID = nil
    }

    func dismissSafetyCheckIn() {
        pendingSafetyCheckInBookingID = nil
    }

    func dismissOrgJoin() {
        pendingOrgJoin = nil
    }

    func dismissOrgJoinSuccess() {
        pendingOrgJoinSuccess = nil
    }

    func endComposeClub() {
        isComposingClub = false
    }

    func beginComposeClub() {
        isComposingClub = true
    }
}
