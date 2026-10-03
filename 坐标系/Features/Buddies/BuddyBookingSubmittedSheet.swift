//
//  BuddyBookingSubmittedSheet.swift
//  坐标系
//
//  预约已提交 / 等待确认 Sheet。
//

import SwiftUI
import CoordinateModels

struct BuddyBookingSubmittedSheet: View {
    let recordID: BuddyBookingRecord.ID
    var onWithdraw: () -> Void
    var onDismiss: () -> Void

    @Environment(BuddiesModel.self) private var buddies
    @Environment(\.dismiss) private var dismiss
    @State private var didAppear = false

    private var record: BuddyBookingRecord? {
        buddies.bookingRecords.first { $0.id == recordID }
    }

    private var statusText: String {
        guard let record else { return BuddyBookingFlowCopy.orderProcessing }
        return BuddyBookingFlowCopy.submittedStatus(for: record)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let record {
                    submittedContent(record)
                } else {
                    ProgressView(BuddyBookingFlowCopy.loadingOrder)
                }
            }
            .navigationTitle(BuddyBookingFlowCopy.submittedTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(BuddyBookingFlowCopy.done) {
                        onDismiss()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { didAppear = true }
            .sensoryFeedback(.success, trigger: didAppear) { _, appeared in appeared }
            .onChange(of: record?.status) { _, status in
                guard let status else { return }
                if status == .awaitingPayment || status == .cancelled {
                    onDismiss()
                    dismiss()
                }
            }
        }
        .platformSheet(.confirm)
        .interactiveDismissDisabled(record?.status == .pendingConfirm)
    }

    @ViewBuilder
    private func submittedContent(_ record: BuddyBookingRecord) -> some View {
        VStack(spacing: PlatformMetrics.sectionSpacing) {
            Spacer(minLength: 12)

            Image(systemName: record.status == .cancelled ? "xmark.circle.fill" : "clock.badge.checkmark.fill")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(record.status == .cancelled ? PlatformStatus.warning : Color.accentColor)

            VStack(spacing: PlatformMetrics.detailMicroSpacing) {
                Text(statusText)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                if record.status == .pendingConfirm {
                    BuddyBookingWaitProgressView(record: record)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, PlatformMetrics.hairlineSpacing)
                }

                Text(BuddyBookingFlowCopy.confirmationDeadlineFooter(for: record))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            summaryCard(record)

            Spacer()

            VStack(spacing: PlatformMetrics.minContentGap) {
                if record.status == .pendingConfirm {
                    Button(BuddyBookingFlowCopy.withdrawBooking, role: .destructive) {
                        onWithdraw()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }

                Button(record.status == .cancelled ? BuddyBookingFlowCopy.gotIt : BuddyBookingFlowCopy.waitInBackground) {
                    onDismiss()
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal, PlatformMetrics.contentInset)
        .padding(.bottom, PlatformMetrics.minContentGap)
    }

    private func summaryCard(_ record: BuddyBookingRecord) -> some View {
        BuddyBookingSummaryCard(record: record)
    }
}
