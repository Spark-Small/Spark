//
//  BookingCredentialExpandedView+Commerce.swift
//  坐标系
//
//  陪玩凭证商务条：待确认 / 待支付 / 退款进度（与履约·联系拆分）。
//

import SwiftUI
import CoordinateModels

extension BookingCredentialExpandedView {

    @ViewBuilder
    func commerceSections(for record: BuddyBookingRecord) -> some View {
        if record.status == .pendingConfirm {
            Section {
                BuddyBookingWaitProgressView(record: record)
            } footer: {
                Text(BuddyBookingFlowCopy.confirmationDeadlineFooter(for: record))
            }
        }

        if record.canPay {
            Section {
                Button {
                    buddies.beginPayment(record.id)
                } label: {
                    Label(BuddyBookingFlowCopy.goToPay, systemImage: "yensign.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())

                Button {
                    contact(record.companionNickname)
                } label: {
                    Label(BuddyBookingFlowCopy.contactCompanion, systemImage: "message.fill")
                        .frame(maxWidth: .infinity)
                }
            } footer: {
                Text(BuddyBookingFlowCopy.paymentDeadlineFooter(for: record))
            }
        }

        if record.status == .refunding,
           let refund = refunds.latestRequest(forOrderID: record.id) {
            Section {
                NavigationLink {
                    RefundStatusView(requestID: refund.id)
                } label: {
                    Label("查看退款进度", systemImage: "arrow.uturn.backward.circle")
                }
            } footer: {
                Text(BuddyBookingFlowCopy.refundingFooter)
            }
        }

        if record.status == .refunded,
           let refund = refunds.latestRequest(forOrderID: record.id) {
            Section {
                NavigationLink {
                    RefundStatusView(requestID: refund.id)
                } label: {
                    Label("查看退款记录", systemImage: "checkmark.circle")
                }
            } footer: {
                Text(BuddyBookingFlowCopy.refundedFooter)
            }
        }
    }
}
