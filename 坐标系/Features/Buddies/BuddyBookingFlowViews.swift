//
//  BuddyBookingFlowViews.swift
//  坐标系
//
//  陪玩下单：待确认、支付成功闭环 Sheet。
//

import SwiftUI

private struct BuddyBookingSummaryCard: View {
    let record: BuddyBookingRecord

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.detailMicroSpacing) {
            LabeledContent(BuddyBookingFlowCopy.companionLabel, value: record.companionNickname)
            LabeledContent("时间") {
                Text(
                    "\(Formatters.monthDay.string(from: record.scheduledAt)) "
                    + Formatters.shortTime.string(from: record.scheduledAt)
                )
            }
            LabeledContent(BuddyBookingFlowCopy.durationLabel, value: "\(record.hours) \(BuddyBookingFlowCopy.hoursUnit)")
            LabeledContent(BuddyBookingFlowCopy.feeLabel, value: record.priceText)
        }
        .font(.subheadline)
        .padding(PlatformMetrics.cardInfoSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
    }
}

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

                Text(BuddyBookingFlowCopy.submittedHint)
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

struct BuddyInviteSuccessSheet: View {
    let record: BuddyInviteRecord
    var activitySubtitle: String?
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var didAppear = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer(minLength: 12)

                hero

                Spacer(minLength: 16)

                actions
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

    private var hero: some View {
        VStack(spacing: PlatformMetrics.sectionSpacing) {
            Image(systemName: "paperplane.circle.fill")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(PlatformStatus.success)

            VStack(spacing: PlatformMetrics.detailMicroSpacing) {
                Text(BuddyBookingFlowCopy.inviteSuccessTitle)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(BuddyBookingFlowCopy.inviteSuccessSubtitle(record.nickname))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: PlatformMetrics.hairlineSpacing) {
                    Text(record.activityTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    if let activitySubtitle {
                        Text(activitySubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, PlatformMetrics.detailMicroSpacing)
            }
            .padding(.horizontal, PlatformMetrics.minContentGap)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        VStack(spacing: PlatformMetrics.cardFooterSpacing) {
            Button {
                onDone()
                dismiss()
            } label: {
                Label(BuddyBookingFlowCopy.done, systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
    }
}
