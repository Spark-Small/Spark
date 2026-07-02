// Module: SparkActivity — Primary info block below cover (title · schedule · location).

import SparkDesignSystem
import SwiftUI

extension ActivityDetailLoadedList {
    @ViewBuilder
    func meetupPrimaryInfoSection(activity: ActivityDetail) -> some View {
        VStack(alignment: .leading, spacing: ActivityDetailMeetupLayout.blockSpacing) {
            Text(activity.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            meetupScheduleRows(activity: activity)

            if !activity.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ActivityDetailLocationRow(
                    activity: activity,
                    onOpenInAppMap: { openMeetupMap(activity: activity) },
                    onOpenExternalMap: { provider in
                        openExternalMap(provider: provider, activity: activity)
                    },
                    onOpenRideHailing: {
                        openRideHailing(activity: activity)
                    }
                )
            }

            meetupRegistrationMetaRow(activity: activity)

            if let message = viewModel.calendarFeedbackMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        .padding(.top, ActivityDetailMeetupLayout.contentSpacing)
    }

    @ViewBuilder
    private func meetupScheduleRows(activity: ActivityDetail) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar")
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .center)
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(ActivityFormatting.detailDateDotWeekdayLine(startsAt: activity.startsAt))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(ActivityFormatting.detailTimeRangeLine(startsAt: activity.startsAt, endsAt: activity.endsAt))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let recurrence = activity.recurrence {
                    Text(ActivityFormatting.detailRecurrenceLine(recurrence))
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                onRequestAddToCalendar()
            } label: {
                Image(systemName: "calendar.badge.plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(
                String(
                    localized: "activity.detail.addCalendar",
                    defaultValue: "加入日历",
                    comment: "Add to calendar"
                )
            )
        }
        .accessibilityElement(children: .combine)
    }

    private func openExternalMap(provider: ActivityMapProvider, activity: ActivityDetail) {
        let directions = activity.lifecycleStatus == .scheduled && activity.rsvpStatus.hasGroupChatAccess
        guard let url = provider.url(locationName: activity.locationName, directions: directions) else { return }
        openURL(url)
    }

    private func openRideHailing(activity: ActivityDetail) {
        guard let url = ActivityMapURL.rideHailingURL(locationName: activity.locationName) else { return }
        openURL(url)
    }
}
