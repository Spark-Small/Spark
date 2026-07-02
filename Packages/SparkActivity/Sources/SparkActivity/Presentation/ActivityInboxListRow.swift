// Module: SparkActivity — Meetup-style activity card row (hero image · schedule · going).

import SparkDesignSystem
import SwiftUI

struct ActivityInboxListRow: View {
    let item: ActivityItem
    let isLocked: Bool
    var onInfoTap: (() -> Void)?
    var onOpenHost: (() -> Void)?
    var onJoin: (() -> Void)?

    @State private var overlayContrast: SparkPhotoOverlayContrast = .unknown

    private var horizontalPadding: CGFloat {
        SparkLayoutMetrics.standardHorizontalPadding
    }

    private var displayInfo: ActivityListCardDisplayInfo {
        ActivityFormatting.listCardDisplayInfo(from: item)
    }

    private var cardCornerRadius: CGFloat {
        SparkLayoutMetrics.activityCardHeroCornerRadius
    }

    private var showsDiscoverJoinButton: Bool {
        onJoin != nil && ActivityBrowseJoinPolicy.showsJoinButton(for: item)
    }

    private var isDiscoverRow: Bool {
        onJoin != nil && onInfoTap != nil
    }

    var body: some View {
        activityCard
            .padding(.top, SparkLayoutMetrics.compactVerticalPadding)
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(accessibilityLabelText)
            .onChange(of: item.id) { _, _ in
                overlayContrast = .unknown
            }
    }

    private var activityCard: some View {
        heroImage
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .strokeBorder(.quaternary, lineWidth: SparkLayoutMetrics.activityCardFrameStrokeWidth)
            }
            .overlay(alignment: .topLeading) {
                if !isLocked, let stageStatus = item.listStageStatus {
                    ActivityStageStatusBadge(status: stageStatus)
                }
            }
    }

    // MARK: - Cover

    private var heroImage: some View {
        ZStack(alignment: .bottom) {
            coverImageContent
                .overlay {
                    if isLocked {
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                            Image(systemName: "lock.fill")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                }

            if !isLocked {
                cardBottomOverlay
            }
        }
        .opacity(isLocked ? 0.72 : 1)
    }

    @ViewBuilder
    private var coverImageContent: some View {
        let cover = ActivityCoverHeroView(
            activityID: item.id,
            title: item.title,
            coverURL: item.coverURL,
            coverPosterURL: item.coverPosterURL,
            coverIsVideo: item.coverIsVideo,
            appliesCornerClip: false,
            onCoverImageLoaded: { overlayContrast = .analyze(image: $0) }
        )

        if isDiscoverRow, let onInfoTap {
            cover
                .contentShape(Rectangle())
                .onTapGesture(perform: onInfoTap)
                .accessibilityLabel(
                    String(
                        localized: "activity.row.openDetail.hint",
                        defaultValue: "查看活动详情",
                        comment: "Activity row opens detail"
                    )
                )
                .accessibilityAddTraits(.isButton)
        } else {
            cover
        }
    }

    @ViewBuilder
    private var cardBottomOverlay: some View {
        if isLocked {
            lockedBottomOverlay
        } else {
            fusedInfoOverlay
        }
    }

    private var hostOverlayAvatarSize: CGFloat {
        SparkLayoutMetrics.activityCardAttendeeAvatarSize + 8
    }

    private var fusedInfoOverlay: some View {
        HStack(alignment: .center, spacing: 12) {
            hostOverlayAvatar

            Group {
                if let onInfoTap {
                    infoOverlayText
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onInfoTap)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint(
                            String(
                                localized: "activity.row.openDetail.hint",
                                defaultValue: "查看活动详情",
                                comment: "Activity row opens detail"
                            )
                        )
                } else {
                    infoOverlayText
                }
            }
            .layoutPriority(0)
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsDiscoverJoinButton {
                discoverJoinButton
                    .layoutPriority(1)
            }
        }
        .cardBottomOverlayChrome(contrast: overlayContrast)
    }

    @ViewBuilder
    private var hostOverlayAvatar: some View {
        if let onOpenHost {
            Button(action: onOpenHost) {
                hostOverlayAvatarContent
            }
            .buttonStyle(.sparkPressable)
            .accessibilityHint(
                String(
                    localized: "activity.host.profile.open.hint",
                    defaultValue: "查看发起人资料",
                    comment: "Open host profile hint"
                )
            )
        } else {
            hostOverlayAvatarContent
        }
    }

    @ViewBuilder
    private var hostOverlayAvatarContent: some View {
        let hostName = item.hostDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if hostName.isEmpty {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: hostOverlayAvatarSize, height: hostOverlayAvatarSize)
                .accessibilityHidden(true)
        } else {
            Text(String(hostName.prefix(1)))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: hostOverlayAvatarSize, height: hostOverlayAvatarSize)
                .background(.quaternary, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(.quaternary, lineWidth: SparkLayoutMetrics.activityCardFrameStrokeWidth)
                }
                .accessibilityLabel(
                    String(
                        format: String(
                            localized: "activity.row.host.a11y.format",
                            defaultValue: "主办 %@",
                            comment: "Host avatar; %@ is display name"
                        ),
                        locale: .current,
                        hostName
                    )
                )
        }
    }

    private var infoOverlayText: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !displayInfo.overlayPrimaryLineParts.isEmpty {
                overlayTextLine(
                    parts: displayInfo.overlayPrimaryLineParts,
                    font: .subheadline,
                    weight: .semibold,
                    role: .primary,
                    contrast: overlayContrast
                )
            }

            if !displayInfo.overlaySecondaryLineParts.isEmpty {
                overlayTextLine(
                    parts: displayInfo.overlaySecondaryLineParts,
                    font: .caption,
                    weight: .regular,
                    role: .secondary,
                    contrast: overlayContrast
                )
            }
        }
    }

    private var discoverJoinButton: some View {
        Button(action: { onJoin?() }) {
            Text(
                String(
                    localized: "activity.browse.join",
                    defaultValue: "加入",
                    comment: "Discover feed join chip"
                )
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, SparkLayoutMetrics.filterChipHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.filterChipVerticalPadding)
            .sparkGlassControl(Capsule())
        }
        .buttonStyle(.sparkPressable)
        .fixedSize(horizontal: true, vertical: false)
        .sparkMinimumTouchTarget()
        .accessibilityLabel(
            String(
                localized: "activity.browse.join",
                defaultValue: "加入",
                comment: "Discover feed join chip"
            )
        )
        .accessibilityHint(
            String(
                localized: "activity.browse.join.hint",
                defaultValue: "打开加入确认",
                comment: "Discover feed join chip hint"
            )
        )
    }

    private var lockedBottomOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)

            lockedPreviewLine
                .foregroundStyle(.secondary)
        }
        .cardBottomOverlayChrome(contrast: overlayContrast)
    }

    private func overlayTextLine(
        parts: [String],
        font: Font,
        weight: Font.Weight,
        role: SparkPhotoOverlayTextRole,
        contrast: SparkPhotoOverlayContrast
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index > 0 {
                    Text("·")
                        .font(font.weight(weight))
                        .foregroundStyle(contrast.foregroundColor(for: role))
                        .padding(.horizontal, 4)
                }
                Text(part)
                    .font(font.weight(weight))
                    .foregroundStyle(contrast.foregroundColor(for: role))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lockedPreviewLine: some View {
        Text(
            String(
                localized: "activity.row.locked.preview",
                defaultValue: "订阅后可查看详情",
                comment: "Locked activity row preview"
            )
        )
        .font(.caption)
        .lineLimit(2)
    }

    // MARK: - Copy helpers

    private var accessibilityLabelText: String {
        if isLocked {
            let format = String(
                localized: "activity.row.locked.format",
                defaultValue: "%@，需订阅",
                comment: "Locked row; %@ is title"
            )
            return String(format: format, locale: .current, item.title)
        }
        return [displayInfo.accessibilitySummary, stageStatusLabel]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    private var stageStatusLabel: String {
        item.listStageStatus?.label ?? ""
    }
}

// MARK: - Card bottom overlay chrome

private extension View {
    /// Bottom gradient scrim for info / join over cover image.
    func cardBottomOverlayChrome(contrast: SparkPhotoOverlayContrast) -> some View {
        padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.activityCardOverlayVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sparkPhotoTextScrim(contrast: contrast)
    }
}

extension ActivityInboxListRow {
    /// Browse/inbox list row.
    ///
    /// REASONING: Discover — info/cover opens detail; join opens confirmation sheet.
    @ViewBuilder
    static func listRow(
        item: ActivityItem,
        at index: Int,
        isItemLocked: (Int) -> Bool,
        onLockedItemTap: (() -> Void)?,
        onOpen: @escaping () -> Void,
        onOpenHost: (() -> Void)? = nil,
        onJoin: (() -> Void)? = nil
    ) -> some View {
        let locked = isItemLocked(index)
        if locked, let onLockedItemTap {
            Button(action: onLockedItemTap) {
                ActivityInboxListRow(item: item, isLocked: true)
            }
            .buttonStyle(.sparkPressable)
            .sparkFlatTabListRow()
            .accessibilityHint(
                String(
                    localized: "activity.row.premium.hint",
                    defaultValue: "订阅后可查看",
                    comment: "Locked activity row"
                )
            )
        } else if onJoin != nil {
            discoverFeedRow(
                item: item,
                onInfoTap: onOpen,
                onOpenHost: onOpenHost,
                onJoin: onJoin
            )
        } else {
            openDetailRow(item: item, onOpen: onOpen)
        }
    }

    private static func discoverFeedRow(
        item: ActivityItem,
        onInfoTap: @escaping () -> Void,
        onOpenHost: (() -> Void)?,
        onJoin: (() -> Void)?
    ) -> some View {
        ActivityInboxListRow(
            item: item,
            isLocked: false,
            onInfoTap: onInfoTap,
            onOpenHost: onOpenHost,
            onJoin: onJoin
        )
        .sparkFlatTabListRow()
    }

    static func openDetailRow(
        item: ActivityItem,
        onOpen: @escaping () -> Void
    ) -> some View {
        Button(action: onOpen) {
            ActivityInboxListRow(item: item, isLocked: false)
        }
        .buttonStyle(.sparkPressable)
        .sparkFlatTabListRow()
        .accessibilityHint(
            String(
                localized: "activity.row.openDetail.hint",
                defaultValue: "查看活动详情",
                comment: "Activity row opens detail"
            )
        )
    }
}

// MARK: - Previews

#Preview("Meetup card") {
    if let hike = MockActivityCatalog.detail(id: "act_1"),
       let coffee = MockActivityCatalog.detail(id: "act_2"),
       let run = MockActivityCatalog.detail(id: "act_3") {
        ScrollView {
            ActivityInboxListRow(
                item: hike.asBrowseListItem(),
                isLocked: false,
                onInfoTap: {},
                onOpenHost: {},
                onJoin: {}
            )
            ActivityInboxListRow(item: coffee.asBrowseListItem(), isLocked: false)
            ActivityInboxListRow(item: run.asListItem(), isLocked: false)
            ActivityInboxListRow(item: hike.asListItem(), isLocked: true)
        }
        .environment(ActivityFavoriteStore())
        .background(.background)
    }
}

#Preview("Meetup card — dark") {
    SparkPreviewSupport.darkMode {
        if let detail = MockActivityCatalog.detail(id: "act_1") {
            ActivityInboxListRow(
                item: detail.asBrowseListItem(),
                isLocked: false,
                onInfoTap: {},
                onJoin: {}
            )
            .environment(ActivityFavoriteStore())
            .background(.background)
        }
    }
}

#Preview("Meetup card — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        if let detail = MockActivityCatalog.detail(id: "act_1") {
            ActivityInboxListRow(
                item: detail.asBrowseListItem(),
                isLocked: false,
                onInfoTap: {},
                onJoin: {}
            )
            .environment(ActivityFavoriteStore())
            .background(.background)
        }
    }
}
