// Module: SparkCommunity — Community detail row components.

import SparkDesignSystem
import SwiftUI

struct CommunityLinkedActivityRow: View {
    let activity: CommunityLinkedActivity
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(activity.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(activity.scheduleLine)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.sectionVerticalPadding)
        }
        .buttonStyle(.sparkPressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                format: String(
                    localized: "community.linkedActivity.row.a11y.format",
                    defaultValue: "%1$@，%2$@",
                    comment: "Linked activity row; title, schedule"
                ),
                locale: .current,
                activity.title,
                activity.scheduleLine
            )
        )
    }
}

struct CommunityFeedPostRow: View {
    let post: CommunityFeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(post.authorDisplayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Text(post.content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            if post.commentCount > 0 || post.likeCount > 0 {
                Text(engagementLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.sectionVerticalPadding)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                format: String(
                    localized: "community.feedPost.row.a11y.format",
                    defaultValue: "%1$@：%2$@",
                    comment: "Feed post row; author, content"
                ),
                locale: .current,
                post.authorDisplayName,
                post.content
            )
        )
    }

    private var engagementLine: String {
        var parts: [String] = []
        if post.likeCount > 0 {
            parts.append(
                String(
                    format: String(
                        localized: "community.feedPost.likes.format",
                        defaultValue: "%lld 赞",
                        comment: "Like count; %lld is count"
                    ),
                    locale: .current,
                    post.likeCount
                )
            )
        }
        if post.commentCount > 0 {
            parts.append(
                String(
                    format: String(
                        localized: "community.feedPost.comments.format",
                        defaultValue: "%lld 回复",
                        comment: "Comment count; %lld is count"
                    ),
                    locale: .current,
                    post.commentCount
                )
            )
        }
        return parts.joined(separator: " · ")
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Linked activity row") {
        CommunityLinkedActivityRow(
            activity: CommunityLinkedActivity(
                id: "act_preview",
                title: String(localized: "community.mock.activity.hike", defaultValue: "周末爬香山", comment: "Activity"),
                scheduleLine: String(
                    localized: "community.mock.activity.schedule",
                    defaultValue: "周六 9:30",
                    comment: "Schedule"
                )
            ),
            onTap: {}
        )
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Feed post row") {
        CommunityFeedPostRow(
            post: CommunityFeedPost(
                id: "post_preview",
                authorDisplayName: String(localized: "community.mock.2.author", defaultValue: "小雨", comment: "Author"),
                authorUserID: "u_host_2",
                authorAvatarURL: MockCommunityAvatarCatalog.authorAvatarURL(userID: "u_host_2"),
                communityName: String(localized: "community.mock.run", defaultValue: "晨跑打卡", comment: "Community"),
                content: String(localized: "community.mock.feed.2", defaultValue: "滨江 5km", comment: "Feed post"),
                imageURL: nil,
                likeCount: 3,
                commentCount: 1,
                tags: [String(localized: "community.mock.tag.run", defaultValue: "跑步", comment: "Tag")],
                createdAt: .now,
                sharedActivityWithViewer: nil,
                relationshipToViewer: .none,
                linkedActivity: nil
            )
        )
    }
}
