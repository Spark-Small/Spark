// Module: SparkCommunity — Community detail row components.

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
        .buttonStyle(.plain)
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
    }
}
