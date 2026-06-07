// Module: SparkCommunity — Community list row in tab footer.

import SparkDesignSystem
import SwiftUI

struct CommunityRowCell: View {
    let community: CommunitySummary

    var body: some View {
        HStack(spacing: 12) {
            communityAvatar
            VStack(alignment: .leading, spacing: 4) {
                Text(community.name)
                    .font(.body.weight(.semibold))
                Text(statsLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !community.bio.isEmpty {
                    Text(community.bio)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            if community.hasNewPosts {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [community.name, statsLine]
        if community.hasNewPosts {
            parts.append(
                String(
                    localized: "community.row.newPosts.a11y",
                    defaultValue: "有新帖子",
                    comment: "New posts indicator"
                )
            )
        }
        if !community.bio.isEmpty {
            parts.append(community.bio)
        }
        return parts.joined(separator: ", ")
    }

    private var statsLine: String {
        let members = String(
            format: String(
                localized: "community.detail.members",
                defaultValue: "%d 名成员",
                comment: "Members; %d count"
            ),
            locale: .current,
            community.memberCount
        )
        let activities = String(
            format: String(
                localized: "community.detail.activities",
                defaultValue: "%d 个活动",
                comment: "Activities; %d count"
            ),
            locale: .current,
            community.activityCount
        )
        return "\(members) · \(activities)"
    }

    @ViewBuilder
    private var communityAvatar: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        if let url = community.coverURL {
            SparkCachedRemoteImage(
                url: url,
                maxPixelSize: 768,
                content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .accessibilityHidden(true)
                },
                placeholder: {
                    Color.clear
                }
            )
            .frame(width: 44, height: 44)
            .sparkGlassSurface(shape)
            .clipShape(shape)
        } else {
            Color.clear
                .frame(width: 44, height: 44)
                .sparkGlassSurface(shape)
        }
    }
}

#Preview {
    CommunityRowCell(
        community: CommunitySummary(
            id: "cm_preview",
            name: "徒步爱好者",
            coverURL: nil,
            memberCount: 128,
            activityCount: 12,
            hasNewPosts: true,
            bio: "周末一起爬山"
        )
    )
    .padding()
}
