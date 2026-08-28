//
//  ProfileSocialViews.swift
//  坐标系
//
//  圈子发现 + 「我的活动」下的陪玩预约凭证 / 活动邀约。
//

import SwiftUI

// MARK: - Circles

struct ProfileCircleDiscoverView: View {
    @Environment(BuddiesModel.self) private var buddies

    var body: some View {
        List {
            if buddies.allCircles.isEmpty {
                ContentUnavailableView(
                    "暂时没有可加入的圈子",
                    systemImage: "person.3",
                    description: Text("附近暂时没有新圈子，稍后再来看看。")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(buddies.allCircles) { circle in
                    NavigationLink(value: CircleBrowseRoute.circle(circle)) {
                        ProfileCircleRow(circle: circle)
                    }
                }
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle("发现圈子")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileCircleRow: View {
    let circle: InterestCircle

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(circle.name)
                    .font(PlatformListTypography.primary)
                Text("\(circle.city) · \(circle.topic)")
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(.secondary)
                Text("\(circle.memberCount) 成员 · 周活跃 \(circle.weeklyActive)")
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(.tertiary)
            }
        } icon: {
            Image(systemName: circle.systemImage)
                .foregroundStyle(.tint)
        }
    }
}

// MARK: - Booking credentials

/// 「我的 → 陪玩预约」：预约凭证与待支付单（订单状态见「我的订单」）。
struct ProfileBookingCredentialsView: View {
    var body: some View {
        List {
            ProfileBookingCredentialsSection()
        }
        .profileSecondaryListChrome()
        .navigationTitle(ProfileDashboardCopy.bookingCredentials)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Activity invites

/// 「我的 → 活动邀约」：搭子页发出的活动邀请记录。
struct ProfileActivityInvitesView: View {
    @Environment(BuddiesModel.self) private var buddies

    var body: some View {
        List {
            Section {
                inviteRows
            } footer: {
                Text("在搭子页邀请同好参加活动后，记录会出现在这里。找新陪玩去「搭子」，好友聊天在「消息」。")
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle(ProfileDashboardCopy.activityInvites)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var inviteRows: some View {
        if buddies.inviteRecords.isEmpty {
            ContentUnavailableView(
                "还没有活动邀约",
                systemImage: "paperplane",
                description: Text("在搭子页邀请同好参加活动后，记录会出现在这里。")
            )
            .listRowBackground(Color.clear)
        } else {
            ForEach(buddies.inviteRecords) { record in
                NavigationLink {
                    BuddyInviteDetailView(recordID: record.id)
                } label: {
                    ProfileInviteRow(record: record)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("删除", systemImage: "trash", role: .destructive) {
                        buddies.deleteInvite(record.id)
                    }
                    #if DEBUG
                    if record.status == .pending {
                        Button("模拟接受", systemImage: "checkmark") {
                            buddies.acceptInvite(record.id)
                        }
                        .tint(.green)
                        Button("模拟婉拒", systemImage: "xmark") {
                            buddies.declineInvite(record.id)
                        }
                        .tint(.orange)
                    }
                    #endif
                }
            }
        }
    }
}

private struct ProfileInviteRow: View {
    let record: BuddyInviteRecord

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
            HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text("邀请 \(record.nickname)")
                    .font(PlatformListTypography.primary)
                Spacer(minLength: 0)
                Text(record.status.rawValue)
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(inviteStatusColor(record.status))
            }

            Text(record.activityTitle)
                .font(PlatformListTypography.secondary)
                .foregroundStyle(.secondary)

            Text(Formatters.activityDate.string(from: record.sentAt))
                .font(PlatformListTypography.footnote)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
    }
}
