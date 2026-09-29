//
//  BuddyCommerceChrome.swift
//  坐标系
//
//  搭子邀约 / 陪玩下单链路 Sheet 宿主。
//  邀约挂在外层；预约挂在 Buddies 栈内，避免跨 TabView 呈现造成竞争。
//

import SwiftUI
import CoordinateModels

extension View {
    /// 邀约链路 Sheet
    func buddyInviteChrome(
        buddies: BuddiesModel,
        activities: ActivitiesModel
    ) -> some View {
        modifier(
            BuddyInviteChromeModifier(
                buddies: buddies,
                activities: activities
            )
        )
    }

    /// 搭子 Tab：选档下单与提交待确认 Sheet
    func buddyBookingChrome(
        buddies: BuddiesModel
    ) -> some View {
        modifier(BuddyBookingFlowChromeModifier(buddies: buddies))
    }

    /// Tab 根：待支付 / 支付 / 成功 / 履约安全确认（「我的」订单详情也会触发）
    func buddyBookingSharedSheets(
        buddies: BuddiesModel,
        app: AppModel,
        peerContactRoute: Binding<PeerContactRoute?>
    ) -> some View {
        modifier(
            BuddyBookingSharedSheetsModifier(
                buddies: buddies,
                app: app,
                peerContactRoute: peerContactRoute
            )
        )
    }
}

private struct BuddyInviteChromeModifier: ViewModifier {
    @Bindable var buddies: BuddiesModel
    var activities: ActivitiesModel

    func body(content: Content) -> some View {
        content
            .sheet(item: $buddies.inviteTarget) { target in
                BuddyInviteSheet(
                    nickname: target.nickname,
                    activities: activities.inviteableActivities
                ) { activity, note in
                    buddies.recordInvite(
                        nickname: target.nickname,
                        activity: activity,
                        note: note
                    )
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(item: inviteSuccessBinding) { record in
                BuddyInviteSuccessSheet(
                    record: record,
                    activitySubtitle: inviteActivitySubtitle(for: record),
                    onDone: {
                        buddies.dismissInviteSuccess()
                    }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
    }

    private var inviteSuccessBinding: Binding<BuddyInviteRecord?> {
        Binding(
            get: {
                guard let id = buddies.pendingInviteSuccessID else { return nil }
                return buddies.inviteRecords.first { $0.id == id }
            },
            set: { if $0 == nil { buddies.dismissInviteSuccess() } }
        )
    }

    private func inviteActivitySubtitle(for record: BuddyInviteRecord) -> String? {
        record.relatedActivityID
            .flatMap { activities.activity(id: $0) }
            .map {
                "\(Formatters.activityDate.string(from: $0.date)) · \($0.location)"
            }
    }
}

private struct BuddyBookingFlowChromeModifier: ViewModifier {
    @Bindable var buddies: BuddiesModel

    func body(content: Content) -> some View {
        content
            .sheet(item: $buddies.bookingPresentation) { presentation in
                BuddyBookingSheet(
                    presentation: presentation
                ) { scheduledAt, hours, slotLabel in
                    _ = buddies.recordBooking(
                        companion: presentation.companion,
                        scheduledAt: scheduledAt,
                        hours: hours,
                        slotLabel: slotLabel
                    )
                } onDismiss: {
                    buddies.dismissBookingPresentation()
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(item: Binding(
                get: { buddies.pendingBookingAcknowledgement },
                set: { if $0 == nil { buddies.dismissBookingAcknowledgement() } }
            )) { record in
                BuddyBookingSubmittedSheet(
                    recordID: record.id,
                    onWithdraw: {
                        buddies.withdrawPendingBooking(record.id)
                        buddies.dismissBookingAcknowledgement()
                    },
                    onDismiss: {
                        buddies.dismissBookingAcknowledgement()
                    }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
    }
}

private struct BuddyBookingSharedSheetsModifier: ViewModifier {
    @Bindable var buddies: BuddiesModel
    var app: AppModel
    @Binding var peerContactRoute: PeerContactRoute?

    func body(content: Content) -> some View {
        content
            .sheet(item: Binding(
                get: { buddies.pendingAwaitingPaymentReview },
                set: { if $0 == nil { buddies.dismissAwaitingPaymentReview() } }
            )) { record in
                BookingAwaitingPaymentSheet(
                    record: record,
                    onPay: {
                        buddies.beginPayment(record.id)
                    },
                    onContactCompanion: {
                        let scheduleLine = PeerChatCopy.bookingScheduleLine(for: record)
                        peerContactRoute = app.openPeerContact(
                            with: record.companionNickname,
                            context: .bookingCompanion(scheduleLine: scheduleLine)
                        )
                        buddies.dismissAwaitingPaymentReview()
                    },
                    onPayLater: {
                        buddies.dismissAwaitingPaymentReview()
                    }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(item: Binding(
                get: { buddies.pendingPaymentBooking },
                set: { if $0 == nil { buddies.cancelPendingPayment() } }
            )) { record in
                BookingPaymentSheet(
                    record: record,
                    onConfirm: { method in
                        buddies.confirmPayment(record.id, method: method)
                    },
                    onCancel: {
                        buddies.cancelPendingPayment()
                    }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(item: bookingSuccessBinding) { record in
                BuddyBookingSuccessSheet(
                    record: record,
                    onOpenBookings: {
                        buddies.dismissBookingSuccess()
                        app.openMyBookings()
                    },
                    onContactCompanion: {
                        let scheduleLine = PeerChatCopy.bookingScheduleLine(for: record)
                        peerContactRoute = app.openPeerContact(
                            with: record.companionNickname,
                            context: .bookingCompanion(scheduleLine: scheduleLine)
                        )
                        buddies.dismissBookingSuccess()
                    },
                    onDone: {
                        buddies.dismissBookingSuccess()
                    }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .sheet(item: Binding(
                get: { buddies.pendingSafetyCheckInBooking },
                set: { if $0 == nil { buddies.cancelPendingSafetyCheckIn() } }
            )) { record in
                TrustSafetyCheckInSheet(record: record) {
                    buddies.cancelPendingSafetyCheckIn()
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
    }

    private var bookingSuccessBinding: Binding<BuddyBookingRecord?> {
        Binding(
            get: {
                guard let id = buddies.pendingBookingSuccessID else { return nil }
                return buddies.bookingRecords.first { $0.id == id }
            },
            set: { if $0 == nil { buddies.dismissBookingSuccess() } }
        )
    }

}
