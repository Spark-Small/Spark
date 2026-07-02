// Module: SparkActivity — Meetup-parity sections (group card · discussion · photos · carousels).

import SparkDesignSystem
import SwiftUI

extension ActivityDetailLoadedList {
    // MARK: - Host group card

    @ViewBuilder
    func meetupHostGroupCardSection(activity: ActivityDetail) -> some View {
        if activity.hostID != nil {
            HStack(alignment: .center, spacing: 12) {
                SparkCachedRemoteImage(
                    url: ActivityCoverImage.url(activityID: activity.id),
                    maxPixelSize: 160,
                    content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .accessibilityHidden(true)
                    },
                    placeholder: {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.quaternary)
                            .overlay {
                                Text(String(activity.displayHostGroupName.prefix(1)))
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                    }
                )
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.displayHostGroupName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let ratingLine = hostRatingLine(activity: activity) {
                        Text(ratingLine)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    } else if let tierBadge = activity.hostTier.localizedBadgeLabel {
                        Text(tierBadge)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(SparkLayoutMetrics.compactVerticalPadding)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius, style: .continuous))
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(hostGroupCardAccessibilityLabel(activity: activity))
        }
    }

    // MARK: - Hosting | Going

    @ViewBuilder
    func meetupHostingGoingSection(activity: ActivityDetail) -> some View {
        if activity.attendeeCount > 0 || !activity.attendees.isEmpty {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
                HStack(spacing: 0) {
                    meetupAttendeeStatColumn(
                        title: String(
                            localized: "activity.detail.hosting.label",
                            defaultValue: "主办",
                            comment: "Hosting count label"
                        ),
                        count: meetupHostingCount(activity: activity)
                    )

                    Divider()
                        .frame(height: 36)
                        .padding(.horizontal, SparkLayoutMetrics.compactVerticalPadding)

                    meetupAttendeeStatColumn(
                        title: String(
                            localized: "activity.detail.going.label",
                            defaultValue: "参加",
                            comment: "Going count label"
                        ),
                        count: meetupGoingCount(activity: activity)
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius, style: .continuous))
                .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)

                if !activity.attendees.isEmpty {
                    ActivityDetailMembersPreviewRow(
                        attendees: activity.attendees,
                        totalCount: activity.attendeeCount
                    )
                }
            }
            .padding(.top, ActivityDetailMeetupLayout.contentSpacing)
        }
    }

    // MARK: - Photos (legacy stub — replaced by ActivityDetailPhotosSection)

    @ViewBuilder
    func meetupPhotosSection(activity: ActivityDetail) -> some View {
        EmptyView()
    }

    // MARK: - Discussion (legacy — replaced by ActivityDetailGroupChatCarousel)

    @ViewBuilder
    func meetupDiscussionSection(activity: ActivityDetail) -> some View {
        EmptyView()
    }

    // MARK: - Event carousels

    @ViewBuilder
    func meetupHostUpcomingCarouselSection(showsAll: Binding<Bool>) -> some View {
        if !viewModel.hostOtherActivities.isEmpty {
            let visibleItems = showsAll.wrappedValue
                ? viewModel.hostOtherActivities
                : Array(viewModel.hostOtherActivities.prefix(3))

            VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
                meetupDetailSubsectionHeader(
                    String(
                        localized: "activity.host.upcoming.section",
                        defaultValue: "即将举办",
                        comment: "Upcoming events from host"
                    )
                )

                if showsAll.wrappedValue {
                    VStack(spacing: SparkLayoutMetrics.compactVerticalPadding) {
                        ForEach(visibleItems) { item in
                            NavigationLink(value: item.id) {
                                ActivityDetailEventCardView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: SparkLayoutMetrics.compactVerticalPadding) {
                            ForEach(visibleItems) { item in
                                NavigationLink(value: item.id) {
                                    ActivityDetailEventCardView(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                    }
                }

                if viewModel.hostOtherActivities.count > 3 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showsAll.wrappedValue.toggle()
                        }
                    } label: {
                        Text(
                            showsAll.wrappedValue
                                ? String(
                                    localized: "activity.host.seeLess",
                                    defaultValue: "收起",
                                    comment: "See fewer host events"
                                )
                                : String(
                                    localized: "activity.host.seeAllEvents",
                                    defaultValue: "查看该群组全部活动",
                                    comment: "See all host events"
                                )
                        )
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                }
            }
        } else if viewModel.hostOtherActivitiesLoadFailed {
            meetupHostEventsLoadFailedSection(
                title: String(
                    localized: "activity.host.upcoming.section",
                    defaultValue: "即将举办",
                    comment: "Upcoming events from host"
                )
            )
        }
    }

    @ViewBuilder
    func meetupHostPastCarouselSection() -> some View {
        if !viewModel.hostPastActivities.isEmpty {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
                meetupDetailSubsectionHeader(
                    String(
                        localized: "activity.host.past.section",
                        defaultValue: "往期活动",
                        comment: "Past events from host"
                    )
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SparkLayoutMetrics.compactVerticalPadding) {
                        ForEach(viewModel.hostPastActivities) { item in
                            NavigationLink(value: item.id) {
                                ActivityDetailEventCardView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                }
            }
        }
    }

    @ViewBuilder
    func meetupSimilarCarouselSection(activity: ActivityDetail) -> some View {
        if !viewModel.similarActivities.isEmpty {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
                meetupDetailSubsectionHeader(
                    String(
                        localized: "activity.detail.similar.section",
                        defaultValue: "同类活动推荐",
                        comment: "Similar activities section"
                    )
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SparkLayoutMetrics.compactVerticalPadding) {
                        ForEach(viewModel.similarActivities) { item in
                            NavigationLink(value: item.id) {
                                ActivityDetailEventCardView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
                }
            }
        } else if viewModel.similarActivitiesLoadFailed {
            meetupHostEventsLoadFailedSection(
                title: String(
                    localized: "activity.detail.similar.section",
                    defaultValue: "同类活动推荐",
                    comment: "Similar activities section"
                ),
                message: String(
                    localized: "activity.detail.similar.failed",
                    defaultValue: "暂时无法加载推荐活动",
                    comment: "Similar activities load failed"
                )
            )
        }
    }

    // MARK: - Report footer

    @ViewBuilder
    func meetupReportFooterSection(activity: ActivityDetail, onReportTapped: (() -> Void)?) -> some View {
        if activity.rsvpStatus != .host, let onReportTapped {
            Button(role: .destructive) {
                onReportTapped()
            } label: {
                Text(
                    String(
                        localized: "activity.report.footer",
                        defaultValue: "举报此活动",
                        comment: "Report event footer"
                    )
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ActivityDetailMeetupLayout.horizontalPadding)
            .padding(.top, ActivityDetailMeetupLayout.sectionTopPadding)
        }
    }

    // MARK: - Helpers

    private func meetupAttendeeStatColumn(title: String, count: Int) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text("\(count)")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    private func meetupHostingCount(activity: ActivityDetail) -> Int {
        let hosts = activity.attendees.filter(\.isHost).count
        return max(hosts, activity.hostID == nil ? 0 : 1)
    }

    private func meetupGoingCount(activity: ActivityDetail) -> Int {
        let going = activity.signupCounts.going
        if going > 0 {
            return going
        }
        return max(0, activity.attendeeCount - meetupHostingCount(activity: activity))
    }

    private func hostRatingLine(activity: ActivityDetail) -> String? {
        guard let rating = activity.hostRating else { return nil }
        let formattedRating = rating.formatted(.number.precision(.fractionLength(1)))
        if let reviewCount = activity.hostReviewCount, reviewCount > 0 {
            let format = String(
                localized: "activity.detail.hostRating.format",
                defaultValue: "%@ · %lld 条评价",
                comment: "Host rating line; first is rating, second is review count"
            )
            return String(format: format, locale: .current, formattedRating, reviewCount)
        }
        return formattedRating
    }

    private func hostGroupCardAccessibilityLabel(activity: ActivityDetail) -> String {
        [activity.displayHostGroupName, hostRatingLine(activity: activity)]
            .compactMap { $0 }
            .joined(separator: ", ")
    }

    @ViewBuilder
    private func meetupHostEventsLoadFailedSection(
        title: String,
        message: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            meetupDetailSubsectionHeader(title)
            Text(
                message
                    ?? String(
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
