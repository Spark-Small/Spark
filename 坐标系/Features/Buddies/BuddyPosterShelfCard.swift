//
//  BuddyPosterShelfCard.swift
//  坐标系
//
//  组织海报轨卡：封面叠字，点整卡进资料（加入在资料内完成，不在卡下挂按钮）。
//

import SwiftUI

/// 搭子第二幕海报卡：封面 + 底文案；整卡可点
struct BuddyPosterShelfCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var fill: Color = Color.accentColor.opacity(0.14)
    var symbolTint: Color = .accentColor
    var badgeTitle: String? = nil
    var badgeTint: Color = PlatformStatus.success
    var accessibilitySummary: String
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: PlatformMetrics.radiusPoster, style: .continuous)
                    .fill(fill)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.largeTitle)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(symbolTint)
                    }
                    .aspectRatio(PlatformMetrics.posterCardAspectRatio, contentMode: .fit)

                if let badgeTitle {
                    PlatformMediaCaptionBadge(title: badgeTitle, tint: badgeTint)
                }
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: PlatformMetrics.minContentGap) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(PlatformMetrics.captionBadgeInset)
                .colorScheme(.dark)
                .allowsHitTesting(false)
            }
            .clipShape(PlatformMetrics.posterShape)
            .contentShape(PlatformMetrics.posterShape)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("打开组织资料")
    }
}

extension BuddyPosterShelfCard {
    static func circle(
        _ circle: InterestCircle,
        onOpen: @escaping () -> Void
    ) -> BuddyPosterShelfCard {
        BuddyPosterShelfCard(
            title: circle.name,
            subtitle: "\(circle.topic) · \(circle.memberCount) 人",
            systemImage: circle.systemImage,
            accessibilitySummary: "\(circle.name)，\(circle.topic)，\(circle.memberCount) 成员",
            onOpen: onOpen
        )
    }
}

struct BuddyGuildDetailView: View {
    let guild: CompanionGuild
    @Environment(BuddiesModel.self) private var buddies
    @State private var toast: String?

    private var isJoined: Bool { buddies.isJoined(guild) }
    private var roster: [PaidCompanion] { buddies.companions(in: guild) }

    var body: some View {
        BuddyOrgInfoScaffold(
            infoTitle: "工会信息",
            nameLabel: "工会名称",
            displayName: guild.name,
            memberCountLabel: max(guild.companionCount, roster.count + (isJoined ? 1 : 0)),
            announcement: guild.summary,
            cityLine: guild.city,
            metaRows: [
                ("擅长", guild.specialty),
                ("起步", guild.priceFromText),
                ("本周单量", "\(guild.weeklyOrders)"),
            ],
            members: roster,
            memberName: { $0.profile.nickname },
            memberDestination: { DiscoverBuddyItem.paid($0) },
            isJoined: isJoined,
            joinTitle: "关注工会",
            leaveTitle: "取消关注",
            pinTitle: "置顶该工会",
            nicknameFieldTitle: "我在本工会的昵称",
            kind: .guild,
            onRequestJoin: { buddies.beginJoin(.guild(guild)) },
            onLeave: { buddies.leaveGuild(guild) },
            onInviteTap: { buddies.beginInvite(to: .guild(guild)) },
            onSearchTap: { toast = "演示：查找工会相关内容" },
            onReport: { toast = "已提交对「\(guild.name)」的投诉" },
            prefs: buddies.prefs(kind: .guild, name: guild.name),
            onPrefsChange: { next in
                buddies.updatePrefs(kind: .guild, name: guild.name) { $0 = next }
            }
        )
        .platformSecondaryPage()
        .navigationDestination(for: DiscoverBuddyItem.self) { item in
            BuddyDetailRouteView(item: item)
        }
        .platformTransientFeedback($toast)
    }
}
