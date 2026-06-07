// Module: SparkCommunity — Read-only comment with relationship context.

import SparkDesignSystem
import SwiftUI

struct CommentRow: View {
    let reply: CommunityPostReply
    let relationship: RelationshipContext

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.communityRowMetaLineSpacing) {
            HStack(spacing: 6) {
                Text(reply.authorDisplayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                RelationshipBadge(context: relationship)
            }
            Text(reply.body)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(SparkLayoutMetrics.communityFeedBodyLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reply.authorDisplayName), \(reply.body)")
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Comment row") {
        CommentRow(
            reply: CommunityPostReply(
                id: "reply_preview",
                body: String(
                    localized: "community.mock.reply.preview",
                    defaultValue: "我也想去，几点集合？",
                    comment: "Preview reply"
                ),
                authorDisplayName: String(
                    localized: "community.mock.1.author",
                    defaultValue: "阿乐",
                    comment: "Author"
                )
            ),
            relationship: .matched
        )
        .padding()
    }
}
