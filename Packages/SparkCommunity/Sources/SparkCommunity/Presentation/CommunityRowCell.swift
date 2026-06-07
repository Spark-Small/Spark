// Module: SparkCommunity — Community list row (groups segment · flat list).

import SparkDesignSystem
import SwiftUI

struct CommunityRowCell: View {
    let community: CommunitySummary

    var body: some View {
        HStack(spacing: 12) {
            communityAvatar
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.communityRowMetaLineSpacing) {
                Text(community.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(statsLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if !community.bio.isEmpty {
                    Text(community.bio)
                        .font(.footnote)
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
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.communityRowVerticalPadding)
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
        let size = SparkLayoutMetrics.communityListAvatarSize
        Group {
            if let url = community.coverURL {
                SparkCachedRemoteImage(
                    url: url,
                    maxPixelSize: 144,
                    content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .accessibilityHidden(true)
                    },
                    placeholder: {
                        avatarPlaceholder
                    }
                )
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var avatarPlaceholder: some View {
        Color(.tertiarySystemFill)
            .overlay {
                Image(systemName: "person.2.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Community row") {
        VStack(spacing: 0) {
            CommunityRowCell(
                community: CommunitySummary(
                    id: "cm_preview",
                    name: String(localized: "community.mock.hike", defaultValue: "爬山队", comment: "Community"),
                    coverURL: nil,
                    memberCount: 128,
                    activityCount: 12,
                    hasNewPosts: true,
                    bio: String(localized: "community.mock.hike.bio", defaultValue: "一起去爬山的人都不会太差", comment: "Bio")
                )
            )
            Divider()
        }
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
    }
}
