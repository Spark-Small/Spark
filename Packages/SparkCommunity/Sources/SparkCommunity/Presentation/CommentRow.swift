// Module: SparkCommunity — Read-only comment with relationship context.

import SwiftUI

struct CommentRow: View {
    let reply: CommunityPostReply
    let relationship: RelationshipContext

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(reply.authorDisplayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                RelationshipBadge(context: relationship)
            }
            Text(reply.body)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reply.authorDisplayName), \(reply.body)")
    }
}
