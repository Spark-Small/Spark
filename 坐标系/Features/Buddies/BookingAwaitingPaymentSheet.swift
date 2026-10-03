//
//  BookingAwaitingPaymentSheet.swift
//  坐标系
//
//  待支付预约 Sheet。
//

import SwiftUI
import CoordinateModels

struct BookingAwaitingPaymentSheet: View {
    let record: BuddyBookingRecord
    var onPay: () -> Void
    var onContactCompanion: () -> Void
    var onPayLater: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showCancellationPolicy = false

    var body: some View {
        NavigationStack {
            VStack(spacing: PlatformMetrics.sectionSpacing) {
                VStack(spacing: PlatformMetrics.detailMicroSpacing) {
                    Text(BuddyBookingFlowCopy.submittedStatus(for: record))
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(BuddyBookingFlowCopy.paymentDeadlineFooter(for: record))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                BuddyBookingSummaryCard(record: record)

                Spacer(minLength: 0)

                VStack(spacing: PlatformMetrics.minContentGap) {
                    Button {
                        onPay()
                        dismiss()
                    } label: {
                        Label(BuddyBookingFlowCopy.goToPay, systemImage: "yensign.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        onContactCompanion()
                    } label: {
                        Label(BuddyBookingFlowCopy.contactCompanion, systemImage: "message.fill")
                            .frame(maxWidth: .infinity)
                    }

                    Button(BuddyBookingFlowCopy.viewCancellationPolicy) {
                        showCancellationPolicy = true
                    }
                    .font(.subheadline)

                    Button(BuddyBookingFlowCopy.payLater) {
                        onPayLater()
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.bottom, PlatformMetrics.minContentGap)
            .navigationTitle(BuddyBookingFlowCopy.awaitingPaymentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .alert(BuddyBookingFlowCopy.viewCancellationPolicy, isPresented: $showCancellationPolicy) {
                Button(BuddyBookingFlowCopy.gotIt, role: .cancel) {}
            } message: {
                Text(BuddyBookingFlowCopy.cancellationPolicyBody)
            }
        }
        .platformSheet(.confirm)
    }
}
