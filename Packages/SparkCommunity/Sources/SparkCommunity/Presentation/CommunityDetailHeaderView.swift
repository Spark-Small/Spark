// Module: SparkCommunity — Instagram-style community detail header.

import SparkDesignSystem
import SwiftUI

struct CommunityDetailHeaderView: View {
    let detail: CommunityDetail
    let members: [CommunityMember]
    let isJoining: Bool
    let onJoin: () -> Void
    let onShowMembers: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.sectionVerticalPadding) {
            coverImage(url: detail.summary.coverURL)
            HStack(alignment: .top, spacing: SparkLayoutMetrics.sectionVerticalPadding) {
                communityIcon(url: detail.summary.coverURL)
                    .offset(y: -SparkLayoutMetrics.communityDetailIconOverlap)
                VStack(alignment: .leading, spacing: 6) {
                    Text(detail.summary.name)
                        .font(.title3.weight(.semibold))
                    Text(statsLine(for: detail.summary))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, SparkLayoutMetrics.communityCarouselRowTopInset)
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)

            if !detail.summary.bio.isEmpty {
                Text(detail.summary.bio)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            }

            HStack(spacing: SparkLayoutMetrics.sectionVerticalPadding) {
                joinButton(isJoined: detail.isJoined)
                memberAvatarStack
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.bottom, SparkLayoutMetrics.sectionVerticalPadding)
        }
    }

    @ViewBuilder
    private func coverImage(url: URL?) -> some View {
        Group {
            if let url {
                SparkCachedRemoteImage(
                    url: url,
                    maxPixelSize: 1_024,
                    content: { image in
                        image.resizable().scaledToFill().accessibilityHidden(true)
                    },
                    placeholder: {
                        Color(.tertiarySystemFill)
                    }
                )
            } else {
                Color(.tertiarySystemFill)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: SparkLayoutMetrics.communityDetailCoverHeight)
        .clipped()
    }

    @ViewBuilder
    private func communityIcon(url: URL?) -> some View {
        Group {
            if let url {
                SparkCachedRemoteImage(
                    url: url,
                    content: { image in
                        image.resizable().scaledToFill().accessibilityHidden(true)
                    },
                    placeholder: {
                        Color(.tertiarySystemFill)
                    }
                )
            } else {
                Color(.tertiarySystemFill)
            }
        }
        .frame(
            width: SparkLayoutMetrics.communityDetailIconSize,
            height: SparkLayoutMetrics.communityDetailIconSize
        )
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(.background, lineWidth: 3)
        }
    }

    @ViewBuilder
    private func joinButton(isJoined: Bool) -> some View {
        if isJoined {
            Label(
                String(localized: "community.detail.joined", defaultValue: "已加入", comment: "Joined"),
                systemImage: "checkmark"
            )
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.composerFieldVerticalPadding)
            .sparkGlassControl(Capsule())
            .sparkMinimumTouchTarget()
            .labelStyle(.titleAndIcon)
        } else {
            Button(action: onJoin) {
                Group {
                    if isJoining {
                        ProgressView()
                    } else {
                        Text(
                            String(
                                localized: "community.detail.join",
                                defaultValue: "加入社区",
                                comment: "Join community"
                            )
                        )
                        .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
                .padding(.vertical, SparkLayoutMetrics.composerFieldVerticalPadding)
                .background(Color.accentColor, in: Capsule())
                .frame(minHeight: SparkLayoutMetrics.minimumTouchTarget)
            }
            .buttonStyle(.sparkPressable)
            .disabled(isJoining)
            .accessibilityHint(
                String(
                    localized: "community.detail.join.hint",
                    defaultValue: "加入后可查看社区帖子和活动",
                    comment: "Join community hint"
                )
            )
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
        .buttonStyle(.sparkPressable)
        .accessibilityLabel(
            String(localized: "community.detail.members.a11y", defaultValue: "查看成员", comment: "View members")
        )
    }

    @ViewBuilder
    private func memberThumb(url: URL?) -> some View {
        Group {
            if let url {
                SparkCachedRemoteImage(
                    url: url,
                    content: { image in
                        image.resizable().scaledToFill().accessibilityHidden(true)
                    },
                    placeholder: {
                        Color(.tertiarySystemFill)
                    }
                )
            } else {
                Color(.tertiarySystemFill)
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
    CommunityPreviewTraits.matrix("Community detail header") {
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
            isJoining: false,
            onJoin: {},
            onShowMembers: {}
        )
    }
}
