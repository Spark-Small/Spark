// Module: SparkDesignSystem — Layout tokens aligned with docs/TAB_SCREENS.md L3.

import SwiftUI

/// Shared spacing, sizing, and corner radii for Presentation layers.
public enum SparkLayoutMetrics {
    // MARK: - Spacing

    public static let standardHorizontalPadding: CGFloat = 16
    public static let compactVerticalPadding: CGFloat = 8
    public static let sectionVerticalPadding: CGFloat = 12

    /// Estimated single chip row height for layout docs and previews.
    public static let floatingChipBarRowHeight: CGFloat = compactVerticalPadding * 2 + minimumTouchTarget

    // MARK: - Filter chips (App Store / TAB_SCREENS L3)

    public static let filterChipHorizontalPadding: CGFloat = 14
    public static let filterChipVerticalPadding: CGFloat = 10
    public static let filterChipSpacing: CGFloat = 8
    public static let filterChipStrokeWidth: CGFloat = 2

    // MARK: - Touch targets (HIG minimum)

    public static let minimumTouchTarget: CGFloat = 44

    // MARK: - Cards & surfaces

    public static let sparkCardCornerRadius: CGFloat = 20
    public static let matchCardCornerRadius: CGFloat = 28
    public static let matchCardMaxWidth: CGFloat = 420
    public static let matchCardPadding: CGFloat = 24

    // MARK: - Likes / discover

    public static let discoverProgressBarHeight: CGFloat = 3
    public static let discoverActionBarSpacing: CGFloat = 20
    public static let discoverActionBarVerticalPadding: CGFloat = 12
    public static let discoverPassButtonSize: CGFloat = 56
    public static let discoverSparkButtonSize: CGFloat = 60
    public static let discoverFriendButtonSize: CGFloat = 52
    public static let discoverLikeButtonSize: CGFloat = 64
    public static let discoverCardInfoPadding: CGFloat = 20
    public static let discoverCardInfoBottomInsetMatch: CGFloat = 88
    public static let discoverCardInfoBottomInsetFriends: CGFloat = 120
    public static let discoverMatchAvatarSize: CGFloat = 88
    public static let discoverMatchAvatarOverlap: CGFloat = 32

    // MARK: - Inbound

    public static let inboundCellCornerRadius: CGFloat = 20
    public static let inboundMediaHeight: CGFloat = 140
    public static let inboundGridSpacing: CGFloat = 12
    public static let inboundInfoBarPadding: CGFloat = 10
    public static let inboundPreviewAvatarSize: CGFloat = 44
    public static let inboundPreviewMaxAvatars: Int = 4
    public static let inboundPreviewSpacing: CGFloat = 12
    public static let discoverRewindButtonSize: CGFloat = 48

    // MARK: - Community

    /// Person avatar in primary-tab flat rows (community feed author, messages inbox).
    public static let tabPersonAvatarSize: CGFloat = 44
    public static let postAuthorAvatarSize: CGFloat = tabPersonAvatarSize
    public static let feedPostTopPadding: CGFloat = 14
    public static let feedPostBottomPadding: CGFloat = 14
    public static let feedSectionHeaderVerticalPadding: CGFloat = 12
    /// Multiline post body / caption (`CommunityPostCard`).
    public static let communityFeedBodyLineSpacing: CGFloat = 6
    /// Stacked metadata under author name (relationship · activity · recap).
    public static let communityFeedMetaLineSpacing: CGFloat = 6
    /// Blocks inside a post (caption · tags · action row).
    public static let communityFeedBlockSpacing: CGFloat = 10
    /// Gap between copy/tags and the engagement row (text posts).
    public static let communityFeedActionsTopSpacing: CGFloat = 6
    /// Gap between engagement row and image caption (gallery posts).
    public static let communityFeedCaptionTopSpacing: CGFloat = 8
    public static let communityFeedActionVerticalPadding: CGFloat = 6
    /// Groups segment `CommunityRowCell` vertical breathing room.
    public static let communityRowVerticalPadding: CGFloat = 12
    public static let communityRowMetaLineSpacing: CGFloat = 5
    public static let communityCarouselAvatarSize: CGFloat = 64
    public static let communityCarouselLabelWidth: CGFloat = 76
    public static let communityListAvatarSize: CGFloat = 48
    public static let communityCarouselHeight: CGFloat = 112
    public static let communityRowDividerLeadingInset: CGFloat = 60
    public static let communityCarouselRowTopInset: CGFloat = 4
    public static let communityCarouselRowBottomInset: CGFloat = 8
    public static let communityDetailCoverHeight: CGFloat = 120
    public static let communityDetailIconSize: CGFloat = 72
    public static let communityDetailIconOverlap: CGFloat = 28
    public static let communityDetailEmptyTabPadding: CGFloat = 32
    public static let communityRecapGalleryHeight: CGFloat = 280
    public static let composeMediaThumbnailSize: CGFloat = 88
    public static let composeMediaThumbnailCornerRadius: CGFloat = 12
    public static let composerFieldHorizontalPadding: CGFloat = 16
    public static let composerFieldVerticalPadding: CGFloat = 10
    public static let segmentedControlMaxWidth: CGFloat = 280

    // MARK: - Tab accessories (iOS 26+)

    /// Extra list bottom inset when tab bottom accessory (create / RSVP) is expanded above the tab bar.
    public static let tabBottomAccessoryScrollInset: CGFloat = 88

    // MARK: - Messages

    public static let inboxRowVerticalPadding: CGFloat = 14
    /// Minimum tap height for `ConversationRow` (Messages / FaceTime Recents–style).
    public static let inboxConversationRowMinHeight: CGFloat = 76
    public static let inboxSectionHeaderTopPadding: CGFloat = 12
    public static let inboxSectionHeaderBottomPadding: CGFloat = 4
    /// Trailing metadata column (time + unread badge) in `ConversationRow`.
    public static let inboxTrailingColumnMinWidth: CGFloat = 44
    /// Numeric unread badge height; single-digit counts use equal width for a circle.
    public static let inboxUnreadBadgeMinSize: CGFloat = 18
    public static let inboxUnreadBadgeWideHorizontalPadding: CGFloat = 6
    public static let inboxAvatarUnreadBadgeOffset: CGFloat = 4
    /// Inner padding for glass module cards on semantic grouped canvas.
    public static let inboxModuleInnerPadding: CGFloat = 14
    public static var inboxModuleListRowInsets: EdgeInsets {
        EdgeInsets(
            top: compactVerticalPadding,
            leading: standardHorizontalPadding,
            bottom: compactVerticalPadding,
            trailing: standardHorizontalPadding
        )
    }

    // MARK: - Activity

    public static let activityInboxRowVerticalPadding: CGFloat = 4
    public static let activityInboxRowSpacing: CGFloat = 12
    public static let activityListDateTileSize: CGFloat = 52
    public static let activityListDateTileCornerRadius: CGFloat = 10
    public static let activityListStatusCapsuleHorizontalPadding: CGFloat = 6
    public static let activityListStatusCapsuleVerticalPadding: CGFloat = 2
    public static let activityFilterVerticalPadding: CGFloat = 8
    /// Meetup-style browse/inbox card hero (`ActivityInboxListRow`).
    public static let activityCardHeroCornerRadius: CGFloat = 20
    public static let activityCardHeroAspectRatio: CGFloat = 16 / 9
    public static let activityCardContentSpacing: CGFloat = 8
    public static let activityCardBottomPadding: CGFloat = 16
    public static let activityStageBadgeHorizontalPadding: CGFloat = 10
    public static let activityStageBadgeVerticalPadding: CGFloat = 6
    public static let activityStageBadgeInnerCornerRadius: CGFloat = 10
    public static let activityCardFrameStrokeWidth: CGFloat = 0.5
    public static let activityCardOverlayVerticalPadding: CGFloat = 14
    public static let activityCardAttendeeAvatarSize: CGFloat = 28
    public static let activityCardAttendeeOverlap: CGFloat = 10

    public static let newMatchAvatarOuter: CGFloat = 64
    public static let newMatchAvatarInner: CGFloat = 56
    public static let newMatchUnreadDotSize: CGFloat = 12
    public static let conversationComposerCornerRadius: CGFloat = 20
    public static let actionCardInnerPadding: CGFloat = inboxModuleInnerPadding

    // MARK: - Profile

    public static let profileAvatarSymbolSize: CGFloat = 72
}

extension View {
    /// Ensures interactive controls meet the HIG 44×44pt minimum touch target.
    public func sparkMinimumTouchTarget(
        _ size: CGFloat = SparkLayoutMetrics.minimumTouchTarget
    ) -> some View {
        frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
    }
}
