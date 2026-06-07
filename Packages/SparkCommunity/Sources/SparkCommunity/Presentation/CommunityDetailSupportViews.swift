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
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(activity.scheduleLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(post.content)
                .font(.subheadline)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
}

#Preview("Community linked activity row") {
    CommunityLinkedActivityRow(
        activity: CommunityLinkedActivity(
            id: "act_preview",
            title: "Weekend hike",
            scheduleLine: "Sat 9:30 · North gate"
        ),
        onTap: {}
    )
}

#Preview("Community feed post row") {
    CommunityFeedPostRow(
        post: CommunityFeedPost(
            id: "post_preview",
            authorDisplayName: "Alex",
            authorUserID: "u_1",
            communityName: "Runners",
            content: "Anyone up for a 5K this evening?",
            imageURL: nil,
            likeCount: 3,
            commentCount: 1,
            tags: ["running"],
            createdAt: .now,
            sharedActivityWithViewer: nil,
            relationshipToViewer: .none,
            linkedActivity: nil
        )
    )
}
