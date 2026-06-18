// Module: SparkActivity — Meetup-style activity card row (hero image · schedule · going).

import SparkDesignSystem
import SwiftUI

struct ActivityInboxListRow: View {
    let item: ActivityItem
    let isLocked: Bool
    /// When true, surfaces host tier + RSVP count for browse discover cards (W7).
    var showsBrowseTrustSignals: Bool = false

    private var horizontalPadding: CGFloat {
        SparkLayoutMetrics.standardHorizontalPadding
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.activityCardContentSpacing) {
            heroImage
                .padding(.top, SparkLayoutMetrics.compactVerticalPadding)
                .padding(.horizontal, horizontalPadding)

            VStack(alignment: .leading, spacing: SparkLayoutMetrics.activityCardContentSpacing) {
                titleBlock
                if showsBrowseTrustSignals {
                    browseSceneLine
                    browseHostLine
                    browseSocialProofLine
                } else {
                    scheduleLine
                    metadataLine
                    if !isLocked {
                        attendeeFooter
                    } else {
                        lockedPreviewLine
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, SparkLayoutMetrics.activityCardBottomPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabelText)
    }

    // MARK: - Hero

    private var heroImage: some View {
        ActivityCoverHeroView(
            activityID: item.id,
            title: item.title,
            showsOverlayActions: !isLocked
        )
        .overlay {
            if isLocked {
                RoundedRectangle(
                    cornerRadius: SparkLayoutMetrics.activityCardHeroCornerRadius,
                    style: .continuous
                )
                .fill(.ultraThinMaterial)
                Image(systemName: "lock.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .opacity(isLocked ? 0.72 : 1)
    }

    // MARK: - Copy

    private var titleBlock: some View {
        Text(item.title)
            .font(.headline.weight(.bold))
            .foregroundStyle(isLocked ? .secondary : .primary)
            .lineSpacing(2)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var scheduleLine: some View {
        if let startsAt = item.startsAt {
            Text(ActivityFormatting.listCardScheduleLine(startsAt: startsAt, endsAt: item.endsAt))
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .lineLimit(1)
        }
    }

    private var browseSceneLine: some View {
        Text(ActivityFormatting.browseSceneLine(category: item.category, startsAt: item.startsAt))
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(2)
    }

    private var browseHostLine: some View {
        HStack(spacing: 6) {
            Text(
                String(
                    format: String(
                        localized: "activity.browse.host.format",
                        defaultValue: "主办 %@",
                        comment: "Browse host; %@ is name"
                    ),
                    locale: .current,
                    item.hostDisplayName.isEmpty
                        ? String(localized: "activity.browse.host.unknown", defaultValue: "主办人", comment: "Unknown host")
                        : item.hostDisplayName
                )
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            if let tierBadge = item.hostTier.localizedBadgeLabel {
                Label(tierBadge, systemImage: "checkmark.seal.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
    }

    private var browseSocialProofLine: some View {
        Text(ActivityFormatting.browseSocialProofLine(attendeeCount: item.attendeeCount))
            .font(.caption.weight(.medium))
            .foregroundStyle(.tertiary)
            .lineLimit(1)
    }

    private var metadataLine: some View {
        Text(metadataText)
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .lineLimit(2)
    }

    private var attendeeFooter: some View {
        ActivityAttendeeAvatarStack(
            hostDisplayName: item.hostDisplayName,
            attendeeCount: max(item.attendeeCount, 1)
        )
    }

    private var lockedPreviewLine: some View {
        Text(
            String(
                localized: "activity.row.locked.preview",
                defaultValue: "订阅后可查看详情",
                comment: "Locked activity row preview"
            )
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }

    // MARK: - Copy helpers

    private var metadataText: String {
        if isLocked {
            return String(
                localized: "activity.row.locked.preview",
                defaultValue: "订阅后可查看详情",
                comment: "Locked activity row preview"
            )
        }
        var parts: [String] = []
        let location = item.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !location.isEmpty {
            parts.append(location)
        }
        if !item.hostDisplayName.isEmpty {
            let format = String(
                localized: "activity.row.hostedBy.format",
                defaultValue: "by %@",
                comment: "Hosted by; %@ is name"
            )
            parts.append(String(format: format, locale: .current, item.hostDisplayName))
        }
        if !item.category.isEmpty {
            parts.append(item.category)
        }
        if let badge = statusBadgeLabel {
            parts.append(badge)
        }
        if parts.isEmpty, !item.summary.isEmpty {
            parts.append(item.summary)
        }
        return parts.joined(separator: " • ")
    }

    private var statusBadgeLabel: String? {
        if item.lifecycleStatus != .scheduled {
            return item.lifecycleStatus.localizedLabel
        }
        return item.lifecycleBadge
    }

    private var accessibilityLabelText: String {
        if isLocked {
            let format = String(
                localized: "activity.row.locked.format",
                defaultValue: "%@，需订阅",
                comment: "Locked row; %@ is title"
            )
            return String(format: format, locale: .current, item.title)
        }
        var parts = [item.title]
        if let startsAt = item.startsAt {
            parts.append(ActivityFormatting.listCardScheduleLine(startsAt: startsAt, endsAt: item.endsAt))
        }
        parts.append(metadataText)
        parts.append(
            String(
                format: String(
                    localized: "activity.row.going.format",
                    defaultValue: "%lld 人参加",
                    comment: "Attendee count; %lld is count"
                ),
                locale: .current,
                item.attendeeCount
            )
        )
        return parts.joined(separator: ", ")
    }
}

// MARK: - Previews

#Preview("Meetup card") {
    if let detail = MockActivityCatalog.detail(id: "act_1") {
        ScrollView {
            ActivityInboxListRow(item: detail.asListItem(), isLocked: false)
            ActivityInboxListRow(item: detail.asListItem(), isLocked: true)
        }
        .environment(ActivityFavoriteStore())
        .background(.background)
    }
}

#Preview("Meetup card — dark") {
    SparkPreviewSupport.darkMode {
        if let detail = MockActivityCatalog.detail(id: "act_1") {
            ActivityInboxListRow(item: detail.asListItem(), isLocked: false)
                .environment(ActivityFavoriteStore())
                .background(.background)
        }
    }
}

#Preview("Meetup card — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        if let detail = MockActivityCatalog.detail(id: "act_1") {
            ActivityInboxListRow(item: detail.asListItem(), isLocked: false)
                .environment(ActivityFavoriteStore())
                .background(.background)
        }
    }
}
