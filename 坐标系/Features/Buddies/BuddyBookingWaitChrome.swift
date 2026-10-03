//
//  BuddyBookingWaitChrome.swift
//  坐标系
//
//  预约等待进度与摘要卡。
//

import SwiftUI
import CoordinateModels

enum BookingWaitStepState {
    case complete
    case current
    case upcoming
}

struct BuddyBookingWaitProgressView: View {
    let record: BuddyBookingRecord

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.detailMicroSpacing) {
            waitStepRow(
                title: BuddyBookingFlowCopy.waitStepSubmitted,
                state: submittedStepState
            )
            waitStepRow(
                title: BuddyBookingFlowCopy.waitStepAwaitingCompanion,
                state: awaitingCompanionStepState
            )
            waitStepRow(
                title: BuddyBookingFlowCopy.waitStepPayment,
                state: paymentStepState
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var submittedStepState: BookingWaitStepState {
        switch record.status {
        case .pendingConfirm, .awaitingPayment, .paid, .inProgress, .completed, .refunding, .refunded:
            return .complete
        case .cancelled:
            return .complete
        }
    }

    private var awaitingCompanionStepState: BookingWaitStepState {
        switch record.status {
        case .pendingConfirm:
            return .current
        case .awaitingPayment, .paid, .inProgress, .completed, .refunding, .refunded:
            return .complete
        case .cancelled:
            return .upcoming
        }
    }

    private var paymentStepState: BookingWaitStepState {
        switch record.status {
        case .pendingConfirm:
            return .upcoming
        case .awaitingPayment:
            return .current
        case .paid, .inProgress, .completed, .refunding, .refunded:
            return .complete
        case .cancelled:
            return .upcoming
        }
    }

    @ViewBuilder
    private func waitStepRow(title: String, state: BookingWaitStepState) -> some View {
        HStack(spacing: PlatformMetrics.minContentGap) {
            Image(systemName: waitStepIcon(for: state))
                .font(.body.weight(.semibold))
                .foregroundStyle(waitStepColor(for: state))
                .frame(width: 22)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(state == .upcoming ? .secondary : .primary)

            Spacer(minLength: 0)

            if state == .current {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: title, state: state))
    }

    private func waitStepIcon(for state: BookingWaitStepState) -> String {
        switch state {
        case .complete:
            "checkmark.circle.fill"
        case .current:
            "clock.fill"
        case .upcoming:
            "circle"
        }
    }

    private func waitStepColor(for state: BookingWaitStepState) -> Color {
        switch state {
        case .complete:
            PlatformStatus.success
        case .current:
            Color.accentColor
        case .upcoming:
            Color.secondary.opacity(0.45)
        }
    }

    private func accessibilityLabel(for title: String, state: BookingWaitStepState) -> String {
        switch state {
        case .complete:
            BuddyBookingFlowCopy.waitStepDoneA11y(title)
        case .current:
            BuddyBookingFlowCopy.waitStepActiveA11y(title)
        case .upcoming:
            BuddyBookingFlowCopy.waitStepPendingA11y(title)
        }
    }
}

struct BuddyBookingSummaryCard: View {
    let record: BuddyBookingRecord

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.detailMicroSpacing) {
            LabeledContent(BuddyBookingFlowCopy.companionLabel, value: record.companionNickname)
            LabeledContent(BuddyBookingFlowCopy.timeLabel) {
                Text(
                    "\(Formatters.monthDay.string(from: record.scheduledAt)) "
                    + Formatters.shortTime.string(from: record.scheduledAt)
                )
            }
            LabeledContent(BuddyBookingFlowCopy.duration, value: "\(record.hours) \(BuddyBookingFlowCopy.hoursUnit)")
            LabeledContent(BuddyBookingFlowCopy.feeLabel, value: record.priceText)
        }
        .font(.subheadline)
        .padding(PlatformMetrics.cardInfoSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
    }
}
