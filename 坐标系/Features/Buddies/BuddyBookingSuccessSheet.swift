//
//  BuddyBookingSuccessSheet.swift
//  坐标系
//
//  预约支付成功 Sheet。
//

import SwiftUI
import CoordinateModels

struct BuddyBookingSuccessSheet: View {
    let record: BuddyBookingRecord
    var onOpenBookings: () -> Void
    var onContactCompanion: () -> Void
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var didAppear = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer(minLength: 12)

                VStack(spacing: PlatformMetrics.sectionSpacing) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(PlatformStatus.success)

                    VStack(spacing: PlatformMetrics.detailMicroSpacing) {
                        Text(BuddyBookingFlowCopy.successTitle)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.center)

                        Text(BuddyBookingFlowCopy.successSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    summaryCard
                }

                Spacer(minLength: 16)

                VStack(spacing: PlatformMetrics.minContentGap) {
                    Button {
                        onContactCompanion()
                        dismiss()
                    } label: {
                        Label(BuddyBookingFlowCopy.contactCompanion, systemImage: "message.fill")
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)

                    Button(BuddyBookingFlowCopy.openMyBookings) {
                        onOpenBookings()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)

                    Button(BuddyBookingFlowCopy.done) {
                        onDone()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.bottom, PlatformMetrics.minContentGap)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(BuddyBookingFlowCopy.done) {
                        onDone()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { didAppear = true }
            .sensoryFeedback(.success, trigger: didAppear) { _, appeared in appeared }
        }
        .platformSheet(.confirm)
    }

    private var summaryCard: some View {
        BuddyBookingSummaryCard(record: record)
    }
}

