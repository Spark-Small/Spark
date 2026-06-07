// Module: SparkActivity — Meetup-style bottom RSVP bar on activity detail.

import SparkDesignSystem
import SwiftUI

struct ActivityDetailRSVPBar: View {
    @Bindable var viewModel: ActivityDetailViewModel
    let activity: ActivityDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let blocked = activity.registrationBlockedMessage {
                Text(blocked)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let error = viewModel.rsvpErrorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 12) {
                rsvpButton(status: .going, isPrimary: true)
                rsvpButton(status: .maybe, isPrimary: false)
            }

            if activity.canJoinWaitlist {
                Button {
                    Task { await viewModel.joinWaitlist() }
                } label: {
                    Text(
                        String(
                            localized: "activity.waitlist.join",
                            defaultValue: "加入候补",
                            comment: "Join waitlist"
                        )
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button {
                Task { await viewModel.submitRSVP(.declined) }
            } label: {
                Text(ActivityRSVPStatus.declined.localizedLabel)
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.isUpdatingRSVP)
        }
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        .background(.bar)
        .disabled(viewModel.isUpdatingRSVP)
    }

    private func rsvpButtonLabel(status: ActivityRSVPStatus, isSelected: Bool) -> some View {
        HStack(spacing: 6) {
            Text(status.localizedLabel)
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func rsvpButton(status: ActivityRSVPStatus, isPrimary: Bool) -> some View {
        let isGoing = status == .going
        let disabled = viewModel.isUpdatingRSVP || (isGoing && !activity.canSelectGoing)
        let isSelected = viewModel.activity?.rsvpStatus == status

        Group {
            if isPrimary {
                Button {
                    Task { await viewModel.submitRSVP(status) }
                } label: {
                    rsvpButtonLabel(status: status, isSelected: isSelected)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    Task { await viewModel.submitRSVP(status) }
                } label: {
                    rsvpButtonLabel(status: status, isSelected: isSelected)
                }
                .buttonStyle(.bordered)
            }
        }
        .disabled(disabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
