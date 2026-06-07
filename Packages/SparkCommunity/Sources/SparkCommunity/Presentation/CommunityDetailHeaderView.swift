// Module: SparkCommunity — Instagram-style community detail header.

import SwiftUI

struct CommunityDetailHeaderView: View {
    let detail: CommunityDetail
    let members: [CommunityMember]
    let onShowMembers: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            coverImage(url: detail.summary.coverURL)
            HStack(alignment: .top, spacing: 12) {
                communityIcon(url: detail.summary.coverURL)
                    .offset(y: -28)
                VStack(alignment: .leading, spacing: 6) {
                    Text(detail.summary.name)
                        .font(.title3.weight(.semibold))
                    Text(statsLine(for: detail.summary))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)

            if !detail.summary.bio.isEmpty {
                Text(detail.summary.bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
            }

            HStack(spacing: 12) {
                joinButton(isJoined: detail.isJoined)
                memberAvatarStack
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private func coverImage(url: URL?) -> some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Rectangle().fill(.thinMaterial)
                    }
                }
            } else {
                Rectangle().fill(.thinMaterial)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .clipped()
    }

    @ViewBuilder
    private func communityIcon(url: URL?) -> some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Circle().fill(.regularMaterial)
                    }
                }
            } else {
                Circle().fill(.regularMaterial)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(.background, lineWidth: 3)
        }
    }

    @ViewBuilder
    private func joinButton(isJoined: Bool) -> some View {
        let label = Text(
            isJoined
                ? String(localized: "community.detail.joined", defaultValue: "已加入 ✓", comment: "Joined")
                : String(localized: "community.detail.join", defaultValue: "加入社区", comment: "Join community")
        )
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)

        if isJoined {
            label
                .background(.thinMaterial, in: Capsule())
        } else {
            label
                .foregroundStyle(.white)
                .background(Color.accentColor, in: Capsule())
        }
    }

    private var memberAvatarStack: some View {
        Button(action: onShowMembers) {
            HStack(spacing: -10) {
                ForEach(members.prefix(4)) { member in
                    memberThumb(url: member.avatarURL)
                }
                if members.count > 4 {
                    Text("+\(members.count - 4)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 6)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            String(localized: "community.detail.members.a11y", defaultValue: "查看成员", comment: "View members")
        )
    }

    @ViewBuilder
    private func memberThumb(url: URL?) -> some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Circle().fill(.thinMaterial)
                    }
                }
            } else {
                Circle().fill(.thinMaterial)
            }
        }
        .frame(width: 28, height: 28)
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(.background, lineWidth: 2)
        }
    }

    private func statsLine(for summary: CommunitySummary) -> String {
        let membersCount = String(
            format: String(
                localized: "community.detail.members",
                defaultValue: "%d 名成员",
                comment: "Members; %d count"
            ),
            locale: .current,
            summary.memberCount
        )
        let activities = String(
            format: String(
                localized: "community.detail.activities",
                defaultValue: "%d 个活动",
                comment: "Activities; %d count"
            ),
            locale: .current,
            summary.activityCount
        )
        let active = String(
            localized: "community.detail.activeThisWeek",
            defaultValue: "本周活跃",
            comment: "Active this week"
        )
        return "\(membersCount) · \(activities) · \(active)"
    }
}

#Preview {
    CommunityDetailHeaderView(
        detail: CommunityDetail(
            summary: CommunitySummary(
                id: "cm_hike",
                name: "徒步爱好者",
                coverURL: nil,
                memberCount: 128,
                activityCount: 12,
                bio: "周末一起爬山"
            ),
            isJoined: true
        ),
        members: [],
        onShowMembers: {}
    )
}
