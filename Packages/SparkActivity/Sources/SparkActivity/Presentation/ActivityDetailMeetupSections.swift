// Module: SparkActivity — Meetup-style detail body (cover · host · schedule · details).

import SparkDesignSystem
import SwiftUI

extension ActivityDetailLoadedList {
    // MARK: - Cover

    @ViewBuilder
    func meetupCoverSection(activity: ActivityDetail) -> some View {
        ActivityCoverHeroView(activityID: activity.id, title: activity.title)
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .padding(.top, SparkLayoutMetrics.compactVerticalPadding)
            .accessibilityElement(children: .contain)
    }

    // MARK: - Title & status

    @ViewBuilder
    func meetupTitleSection(activity: ActivityDetail) -> some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.activityCardContentSpacing) {
            Text(activity.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            meetupStatusBadges(activity: activity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        .padding(.top, ActivityDetailMeetupLayout.contentSpacing)
    }

    // MARK: - Host (Meetup: Hosted by …)

    @ViewBuilder
    func meetupHostSection(activity: ActivityDetail) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(String(activity.hostDisplayName.prefix(1)))
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(.quaternary, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(
                    String(
                        format: String(
                            localized: "activity.detail.hostedBy.inline.format",
                            defaultValue: "Hosted by %@",
                            comment: "Meetup host line; %@ is name"
                        ),
                        locale: .current,
                        activity.hostDisplayName
                    )
                )
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

                if let tierBadge = activity.hostTier.localizedBadgeLabel {
                    Text(tierBadge)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else if activity.rsvpStatus == .host {
                    Text(
                        String(
                            localized: "activity.detail.host.organizer.badge",
                            defaultValue: "主办人",
                            comment: "Host organizer badge"
                        )
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                }

                if let bio = activity.hostBio, !bio.isEmpty {
                    Text(bio)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        .padding(.top, ActivityDetailMeetupLayout.contentSpacing)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Group / category

    @ViewBuilder
    func meetupGroupSection(activity: ActivityDetail) -> some View {
        if !activity.category.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "person.3.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)

                Text(activity.category)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .padding(.top, ActivityDetailMeetupLayout.contentSpacing)
        }
    }

    // MARK: - Schedule & location

    @ViewBuilder
    func meetupScheduleLocationSection(activity: ActivityDetail) -> some View {
        VStack(alignment: .leading, spacing: ActivityDetailMeetupLayout.blockSpacing) {
            meetupIconRow(
                systemImage: "calendar",
                title: ActivityFormatting.detailMeetupScheduleLine(
                    startsAt: activity.startsAt,
                    endsAt: activity.endsAt
                ),
                subtitle: activity.recurrence.map(ActivityFormatting.detailRecurrenceLine)
            )

            if !activity.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                meetupIconRow(
                    systemImage: "mappin.and.ellipse",
                    title: activity.locationName,
                    subtitle: nil
                )

                ActivityMeetupMapPreview(
                    activityTitle: activity.title,
                    locationName: activity.locationName
                )
            }
        }
        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        .padding(.top, ActivityDetailMeetupLayout.contentSpacing)
    }

    // MARK: - Attendees preview

    @ViewBuilder
    func meetupAttendeesPreviewSection(activity: ActivityDetail) -> some View {
        if activity.attendeeCount > 0 {
            ActivityAttendeeAvatarStack(
                displayNames: attendeePreviewNames(activity: activity),
                attendeeCount: activity.attendeeCount
            )
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .padding(.top, ActivityDetailMeetupLayout.contentSpacing)
        }
    }

    // MARK: - Details (Meetup "Details")

    @ViewBuilder
    func meetupDetailsSection(activity: ActivityDetail) -> some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.communityFeedBlockSpacing) {
            meetupDetailSectionHeader(
                String(
                    localized: "activity.detail.details.section",
                    defaultValue: "活动详情",
                    comment: "Meetup details section"
                )
            )

            Text(activity.description)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(SparkLayoutMetrics.communityFeedBodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
        }
    }

    // MARK: - Related topic (category tag)

    @ViewBuilder
    func meetupRelatedTopicsSection(activity: ActivityDetail) -> some View {
        if !activity.category.isEmpty {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
                meetupDetailSubsectionHeader(
                    String(
                        localized: "activity.detail.relatedTopics.section",
                        defaultValue: "相关主题",
                        comment: "Related topics"
                    )
                )

                Text(activity.category)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.quaternary, in: Capsule())
                    .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            }
        }
    }

    // MARK: - Host other events

    @ViewBuilder
    func meetupHostOtherEventsSection() -> some View {
        if !viewModel.hostOtherActivities.isEmpty {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
                meetupDetailSubsectionHeader(
                    String(
                        localized: "activity.host.more.section",
                        defaultValue: "主办的其他活动",
                        comment: "More from host"
                    )
                )

                VStack(spacing: 0) {
                    ForEach(viewModel.hostOtherActivities) { item in
                        NavigationLink(value: item) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text(item.scheduleLine)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
                        }
                        .buttonStyle(.plain)

                        if item.id != viewModel.hostOtherActivities.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            }
        } else if viewModel.hostOtherActivitiesLoadFailed {
            VStack(alignment: .leading, spacing: 4) {
                meetupDetailSubsectionHeader(
                    String(
                        localized: "activity.host.more.section",
                        defaultValue: "主办的其他活动",
                        comment: "More from host"
                    )
                )
                Text(
                    String(
                        localized: "activity.host.more.failed",
                        defaultValue: "暂时无法加载主办的其他活动",
                        comment: "Host more load failed"
                    )
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            }
        }
    }

    // MARK: - Helpers

    private func meetupIconRow(systemImage: String, title: String, subtitle: String?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private func attendeePreviewNames(activity: ActivityDetail) -> [String] {
        let names = activity.attendees.map(\.displayName).filter { !$0.isEmpty }
        if names.isEmpty, !activity.hostDisplayName.isEmpty {
            return [activity.hostDisplayName]
        }
        return names
    }

    @ViewBuilder
    private func meetupStatusBadges(activity: ActivityDetail) -> some View {
        let badges = meetupBadgeLabels(activity: activity)
        if !badges.isEmpty {
            HStack(spacing: 8) {
                ForEach(badges, id: \.self) { badge in
                    Text(badge)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .sparkGlassControl(Capsule())
                }
            }
        }
    }

    private func meetupBadgeLabels(activity: ActivityDetail) -> [String] {
        var labels: [String] = []
        if activity.lifecycleStatus != .scheduled {
            labels.append(activity.lifecycleStatus.localizedLabel)
        }
        if activity.rsvpStatus != .invited {
            labels.append(activity.rsvpStatus.localizedLabel)
        }
        return labels
    }
}
