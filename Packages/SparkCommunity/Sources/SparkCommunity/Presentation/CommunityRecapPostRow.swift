// Module: SparkCommunity — Recap post summary row for filtered feed.

import SparkDesignSystem
import SwiftUI

struct CommunityRecapPostRow: View {
    let post: CommunityPost
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 6) {
                Label(
                    String(
                        localized: "community.recap.badge",
                        defaultValue: "活动复盘",
                        comment: "Recap badge"
                    ),
                    systemImage: "calendar.badge.clock"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                Text(post.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)

                if let activityTitle = post.linkedActivityTitle {
                    Text(activityTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(post.excerpt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.sparkPressable)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                format: String(
                    localized: "community.recap.row.a11y.format",
                    defaultValue: "活动复盘：%1$@",
                    comment: "Recap row; post title"
                ),
                locale: .current,
                post.title
            )
        )
    }
}

#Preview {
    CommunityRecapPostRow(
        post: CommunityPost(
            id: "cp_recap_1",
            title: "「玉林咖啡局」复盘",
            excerpt: "氛围很好，认识了几位新朋友。",
            authorDisplayName: "Nova",
            replyCount: 0,
            kind: .activityRecap,
            linkedActivityID: "act_browse_2",
            linkedActivityTitle: "玉林咖啡聊天局"
        ),
        onOpen: {}
    )
}
