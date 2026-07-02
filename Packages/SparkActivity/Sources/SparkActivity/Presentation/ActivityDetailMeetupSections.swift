// Module: SparkActivity — Meetup-style detail body (cover · club · description helpers).

import SparkDesignSystem
import SwiftUI

extension ActivityDetailLoadedList {
    // MARK: - Cover

    @ViewBuilder
    func meetupCoverSection(activity: ActivityDetail) -> some View {
        ActivityCoverHeroView(
            activityID: activity.id,
            title: activity.title,
            coverURL: activity.coverURL,
            coverPosterURL: activity.coverPosterURL,
            coverIsVideo: activity.coverIsVideo,
            appliesCornerClip: false
        )
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    func meetupClubSection(activity: ActivityDetail) -> some View {
        if activity.hostID != nil {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
                meetupDetailSubsectionHeader(
                    String(
                        localized: "activity.detail.club.section",
                        defaultValue: "俱乐部",
                        comment: "Host club section"
                    )
                )
                meetupHostGroupCardSection(activity: activity)
                    .padding(.top, 0)
            }
        }
    }

    @ViewBuilder
    func meetupDescriptionSection(activity: ActivityDetail) -> some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            ActivityDetailExpandableDescription(text: activity.description)
                .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        }
        .padding(.top, ActivityDetailMeetupLayout.contentSpacing)
    }

    @ViewBuilder
    func meetupGroupChatSection(
        activity: ActivityDetail,
        onOpenGroupChat: ((ActivityDetail) async -> Void)?
    ) -> some View {
        if meetupShowsGroupChat(for: activity) {
            ActivityDetailGroupChatCarousel(
                entries: activity.groupChatEntries,
                hasAccess: activity.rsvpStatus.hasGroupChatAccess,
                onOpenChat: { _ in
                    guard let onOpenGroupChat else { return }
                    Task { await onOpenGroupChat(activity) }
                }
            )
        }
    }

    @ViewBuilder
    func meetupRegistrationMetaRow(activity: ActivityDetail) -> some View {
        HStack(spacing: 8) {
            Text(activity.displayPriceLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .sparkGlassControl(Capsule())

            Text(activity.attendeeLine)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            if activity.isAtCapacity {
                Text(
                    String(localized: "activity.detail.soldOut", defaultValue: "已满员", comment: "Activity at capacity")
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .sparkGlassControl(Capsule())
            } else if let spotsLine = activity.spotsRemainingLine {
                Text(spotsLine)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, SparkLayoutMetrics.compactVerticalPadding)
        .accessibilityElement(children: .combine)
    }

    func openMeetupMap(activity: ActivityDetail) {
        meetupMapRoute = ActivityMeetupMapRoute(
            activityTitle: activity.title,
            locationName: activity.locationName,
            showsDirections: activity.lifecycleStatus == .scheduled
                && activity.rsvpStatus.hasGroupChatAccess
        )
    }
}
