// Module: SparkCommunity — Community list row in tab footer.

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
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
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
        if let url = community.coverURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    RoundedRectangle(cornerRadius: 10).fill(.thinMaterial)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(.thinMaterial)
                .frame(width: 44, height: 44)
        }
    }
}
