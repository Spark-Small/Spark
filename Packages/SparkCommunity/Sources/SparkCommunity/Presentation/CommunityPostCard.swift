// Module: SparkCommunity — Feed post row (Threads / Instagram-style · TYPOGRAPHY.md).

import SparkCore
import SparkDesignSystem
import SwiftUI

struct CommunityPostCard: View {
    let post: CommunityFeedPost
    let isLiked: Bool
    let likeCount: Int
    let isLikePending: Bool
    let onToggleLike: () -> Void
    let onOpen: () -> Void
    var onOpenAuthor: (() -> Void)?
    var onOpenLinkedActivity: ((String) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isExpanded = false

    private var contentHorizontalPadding: CGFloat {
        SparkLayoutMetrics.standardHorizontalPadding
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            authorHeader
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.top, SparkLayoutMetrics.feedPostTopPadding)
                .padding(.bottom, SparkLayoutMetrics.communityFeedMetaLineSpacing)

            if post.hasGalleryMedia {
                galleryPostBody
            } else {
                textOnlyPostBody
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        Divider()
    }

    // MARK: - Post layouts

    private var textOnlyPostBody: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.communityFeedBlockSpacing) {
            postBodyText
            linkedActivitySummaryCard
            CommunityPostTagsRow(tags: post.tags)
            actionRow
        }
        .padding(.horizontal, contentHorizontalPadding)
        .padding(.bottom, SparkLayoutMetrics.feedPostBottomPadding)
    }

    private var galleryPostBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            CommunityPostMediaPager(
                mediaItems: post.galleryMedia,
                usesInsetMedia: false,
                horizontalPadding: contentHorizontalPadding,
                onOpen: onOpen
            )
            actionRow
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.vertical, SparkLayoutMetrics.communityFeedActionVerticalPadding)
            imagePostCaption
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.top, SparkLayoutMetrics.communityFeedCaptionTopSpacing)
                .padding(.bottom, SparkLayoutMetrics.feedPostBottomPadding)
        }
    }

    // MARK: - Author

    private var authorHeader: some View {
        Group {
            if let onOpenAuthor {
                Button(action: onOpenAuthor) {
                    authorIdentityContent
                }
                .buttonStyle(.plain)
                .accessibilityLabel(authorAccessibilityLabel)
                .accessibilityHint(
                    String(
                        localized: "community.post.author.profile.hint",
                        defaultValue: "查看作者资料",
                        comment: "Open author profile hint"
                    )
                )
            } else {
                authorIdentityContent
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(authorAccessibilityLabel)
            }
        }
    }

    private var authorIdentityContent: some View {
        HStack(alignment: .top, spacing: 12) {
            authorAvatar
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.communityFeedMetaLineSpacing) {
                authorNameRow
                if !post.hasGalleryMedia {
                    relationshipHighlightLine
                    activityContextRow
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var feedContextLines: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.communityFeedMetaLineSpacing) {
            relationshipHighlightLine
            activityContextRow
        }
    }

    /// L1: 作者 · 社区名（若有）· 时间
    private var authorNameRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(post.authorDisplayName)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .layoutPriority(1)
            if !post.communityName.isEmpty {
                metadataSeparator
                Text(post.communityName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(relativeTime)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    /// L2: 熟人关系 — Plan A 最高优先级（共同活动 / 配对 / 喜欢过）
    @ViewBuilder
    private var relationshipHighlightLine: some View {
        if let shared = post.sharedActivityWithViewer {
            Text(
                String(
                    format: String(
                        localized: "community.post.sharedActivity",
                        defaultValue: "和你去了 %@",
                        comment: "Shared activity; %@ is name"
                    ),
                    locale: .current,
                    shared.name
                )
            )
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .lineSpacing(SparkLayoutMetrics.communityFeedBodyLineSpacing)
            .lineLimit(2)
        } else if post.relationshipToViewer != .none {
            RelationshipBadge(context: post.relationshipToViewer)
        }
    }

    /// L3: 关联活动 · 局后随拍（recap）；关联活动与 L2 重复时不二次展示
    @ViewBuilder
    private var activityContextRow: some View {
        if showsActivityContextRow {
            HStack(spacing: 6) {
                if let linked = post.linkedActivity, !isLinkedActivityRedundantWithShared {
                    Label(linked.name, systemImage: "calendar")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .labelStyle(.titleAndIcon)
                        .lineLimit(1)
                }
                if post.kind == .activityRecap {
                    if post.linkedActivity != nil, !isLinkedActivityRedundantWithShared {
                        metadataSeparator
                    }
                    activityShareBadge
                }
            }
        }
    }

    private var showsActivityContextRow: Bool {
        if post.kind == .activityRecap { return true }
        if post.linkedActivity != nil, !isLinkedActivityRedundantWithShared { return true }
        return false
    }

    private var isLinkedActivityRedundantWithShared: Bool {
        guard let shared = post.sharedActivityWithViewer,
              let linked = post.linkedActivity
        else { return false }
        return shared.id == linked.id || shared.name == linked.name
    }

    @ViewBuilder
    private var linkedActivitySummaryCard: some View {
        if showsLinkedActivitySummaryCard, let linked = post.linkedActivity {
            CommunityPostLinkedActivitySummaryCard(activity: linked) {
                onOpenLinkedActivity?(linked.id)
            }
            .disabled(onOpenLinkedActivity == nil)
        }
    }

    private var showsLinkedActivitySummaryCard: Bool {
        post.linkedActivity != nil && !isLinkedActivityRedundantWithShared
    }

    private var metadataSeparator: some View {
        Text("·")
            .font(.footnote)
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }

    private var activityShareBadge: some View {
        Label(
            String(
                localized: "community.activityShare.badge",
                defaultValue: "局后随拍",
                comment: "Activity share post badge"
            ),
            systemImage: "photo.on.rectangle.angled"
        )
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.secondary)
        .labelStyle(.titleAndIcon)
    }

    private var authorAccessibilityLabel: String {
        var parts = [post.authorDisplayName]
        if !post.communityName.isEmpty {
            parts.append(post.communityName)
        }
        parts.append(relativeTime)
        if let shared = post.sharedActivityWithViewer {
            parts.append(
                String(
                    format: String(
                        localized: "community.post.sharedActivity",
                        defaultValue: "和你去了 %@",
                        comment: "Shared activity; %@ is name"
                    ),
                    locale: .current,
                    shared.name
                )
            )
        }
        if let linked = post.linkedActivity, !isLinkedActivityRedundantWithShared {
            parts.append(linked.name)
        }
        if post.kind == .activityRecap {
            parts.append(
                String(
                    localized: "community.activityShare.badge",
                    defaultValue: "局后随拍",
                    comment: "Activity share post badge"
                )
            )
        }
        return parts.joined(separator: ", ")
    }

    private var authorAvatar: some View {
        Group {
            if let avatarURL = post.authorAvatarURL {
                SparkCachedRemoteImage(
                    url: avatarURL,
                    maxPixelSize: 128,
                    content: { image in
                        image.resizable().scaledToFill().accessibilityHidden(true)
                    },
                    placeholder: {
                        authorAvatarPlaceholder
                    }
                )
            } else {
                authorAvatarPlaceholder
            }
        }
        .frame(
            width: SparkLayoutMetrics.postAuthorAvatarSize,
            height: SparkLayoutMetrics.postAuthorAvatarSize
        )
        .clipShape(Circle())
    }

    private var authorAvatarPlaceholder: some View {
        Text(String(post.authorDisplayName.prefix(1)))
            .font(.callout.weight(.semibold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .sparkGlassControl(Circle())
    }

    // MARK: - Copy

    private var postBodyText: some View {
        Button(action: onOpen) {
            Text(post.content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(SparkLayoutMetrics.communityFeedBodyLineSpacing)
                .multilineTextAlignment(.leading)
                .lineLimit(isExpanded ? nil : 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.plain)
    }

    private var imagePostCaption: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.communityFeedBlockSpacing) {
            feedContextLines
            captionBody
            linkedActivitySummaryCard
            if !isExpanded, post.content.count > 100 {
                Button(
                    String(localized: "community.post.readMore", defaultValue: "更多", comment: "Read more")
                ) {
                    isExpanded = true
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            CommunityPostTagsRow(tags: post.tags)
        }
    }

    private var captionBody: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.communityFeedMetaLineSpacing) {
                Text(post.authorDisplayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(post.content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(SparkLayoutMetrics.communityFeedBodyLineSpacing)
                    .multilineTextAlignment(.leading)
                    .lineLimit(isExpanded ? nil : 3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private var actionRow: some View {
        HStack(spacing: 20) {
            CommunityPostLikeControl(
                isLiked: isLiked,
                likeCount: likeCount,
                isPending: isLikePending,
                onToggle: onToggleLike
            )

            Button(action: onOpen) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                    if post.commentCount > 0 {
                        Text("\(post.commentCount)")
                    }
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .sparkMinimumTouchTarget()
            .accessibilityLabel(
                String(
                    localized: "community.post.comments.a11y",
                    defaultValue: "评论",
                    comment: "Comments"
                )
            )

            Spacer(minLength: 0)
        }
        .font(.subheadline)
    }

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: post.createdAt, relativeTo: Date())
    }
}

// MARK: - Previews

#Preview("Recap + linked activity") {
    CommunityPostCard(
        post: CommunityFeedPost(
            id: "cp_recap",
            authorDisplayName: "Nova",
            authorUserID: "u_guest_1",
            communityName: String(localized: "community.mock.book", defaultValue: "读书会", comment: "Community"),
            content: String(
                localized: "community.mock.feed.activityShare",
                defaultValue: "玉林咖啡局氛围很好，认识了几位新朋友，下次还想来。",
                comment: "Activity share feed post"
            ),
            imageURL: URL(string: "https://picsum.photos/seed/feed-recap/800/450"),
            mediaItems: SparkGalleryMediaFactory.mockActivityGallery(activityID: "act_browse_2"),
            likeCount: 9,
            commentCount: 2,
            createdAt: .now.addingTimeInterval(-7_200),
            linkedActivity: LinkedActivityContext(
                id: "act_browse_2",
                name: String(localized: "community.mock.activity.book", defaultValue: "咖啡聊天局", comment: "Activity")
            ),
            kind: .activityRecap
        ),
        isLiked: false,
        likeCount: 9,
        isLikePending: false,
        onToggleLike: {},
        onOpen: {}
    )
}

#Preview("Shared activity") {
    CommunityPostCard(
        post: CommunityFeedPost(
            id: "cp_1",
            authorDisplayName: "阿乐",
            authorUserID: "u_host_1",
            communityName: String(localized: "community.mock.hike", defaultValue: "爬山队", comment: "Community"),
            content: String(
                localized: "community.mock.feed.1",
                defaultValue: "昨天的山顶日出太美了！推荐大家周末一起走香山大环线。",
                comment: "Feed post"
            ),
            imageURL: URL(string: "https://picsum.photos/seed/feed-1/800/450"),
            likeCount: 24,
            commentCount: 6,
            createdAt: .now.addingTimeInterval(-10_800),
            sharedActivityWithViewer: SharedActivityContext(
                id: "act_001",
                name: String(localized: "community.mock.activity.hike", defaultValue: "周末爬香山", comment: "Activity")
            ),
            linkedActivity: LinkedActivityContext(
                id: "act_001",
                name: String(localized: "community.mock.activity.hike", defaultValue: "周末爬香山", comment: "Activity")
            )
        ),
        isLiked: true,
        likeCount: 25,
        isLikePending: false,
        onToggleLike: {},
        onOpen: {}
    )
}

#Preview("Text only") {
    CommunityPostCard(
        post: CommunityFeedPost(
            id: "cp_text",
            authorDisplayName: "小雨",
            authorUserID: "u_host_2",
            communityName: String(localized: "community.mock.book", defaultValue: "读书会", comment: "Community"),
            content: String(
                localized: "community.mock.feed.2",
                defaultValue: "滨江 5km，配速 6 分。坚持一个月，膝盖状态不错。",
                comment: "Feed post"
            ),
            likeCount: 11,
            commentCount: 5,
            createdAt: .now.addingTimeInterval(-86_400)
        ),
        isLiked: false,
        likeCount: 11,
        isLikePending: false,
        onToggleLike: {},
        onOpen: {}
    )
}

#Preview("Dark · accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        SparkPreviewSupport.darkMode {
            CommunityPostCard(
                post: CommunityFeedPost(
                    id: "cp_dark",
                    authorDisplayName: "Nova",
                    authorUserID: "u_guest_1",
                    communityName: "读书会",
                    content: "玉林咖啡局氛围很好，认识了几位新朋友。",
                    imageURL: URL(string: "https://picsum.photos/seed/feed-recap/800/450"),
                    likeCount: 9,
                    commentCount: 2,
                    createdAt: .now,
                    linkedActivity: LinkedActivityContext(id: "a1", name: "咖啡聊天局"),
                    kind: .activityRecap
                ),
                isLiked: false,
                likeCount: 9,
                isLikePending: false,
                onToggleLike: {},
                onOpen: {}
            )
        }
    }
}
