//
//  ProfileSocialViews.swift
//  坐标系
//
//  圈子发现 + 「我的活动」下的陪玩预约凭证 / 活动邀约。
//

import SwiftUI
import CoordinateModels

// MARK: - Circles

struct ProfileMyClubsView: View {
    @Environment(BuddiesModel.self) private var buddies

    private var joined: [InterestCircle] { buddies.joinedCircles }
    private var hosted: [InterestCircle] { buddies.hostedClubs }

    private var joinedOthers: [InterestCircle] {
        let hostedIDs = Set(hosted.map(\.id))
        return joined.filter { !hostedIDs.contains($0.id) }
    }

    var body: some View {
        List {
            if joined.isEmpty {
                ContentUnavailableView(
                    ProfileDashboardCopy.myClubsEmpty,
                    systemImage: "person.3",
                    description: Text(ProfileDashboardCopy.myClubsEmptyHint)
                )
                .listRowBackground(Color.clear)
            } else {
                if !hosted.isEmpty {
                    Section(ProfileDashboardCopy.myClubsHosted) {
                        ForEach(hosted) { circle in
                            NavigationLink(value: CircleBrowseRoute.circle(circle)) {
                                ProfileCircleRow(circle: circle, showsCreatorBadge: true)
                            }
                        }
                    }
                }

                if !joinedOthers.isEmpty {
                    Section(ProfileDashboardCopy.myClubsJoined) {
                        ForEach(joinedOthers) { circle in
                            NavigationLink(value: CircleBrowseRoute.circle(circle)) {
                                ProfileCircleRow(circle: circle)
                            }
                        }
                    }
                }
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle(ProfileDashboardCopy.myClubsTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfileCircleDiscoverView: View {
    @Environment(BuddiesModel.self) private var buddies

    var body: some View {
        List {
            if buddies.allCircles.isEmpty {
                ContentUnavailableView(
                    "暂时没有可加入的俱乐部",
                    systemImage: "person.3",
                    description: Text("附近暂时没有新俱乐部，稍后再来看看。")
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
        .navigationTitle("发现俱乐部")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileCircleRow: View {
    let circle: InterestCircle
    var showsCreatorBadge = false

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                HStack(spacing: PlatformMetrics.minContentGap) {
                    Text(circle.name)
                        .font(PlatformListTypography.primary)
                    if showsCreatorBadge {
                        Text("我创建")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(PlatformAction.cloverPurple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(PlatformAction.cloverPurple.opacity(0.12), in: Capsule())
                    }
                }
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

// MARK: - My clubs shelf

struct ProfileMyClubsShelf: View {
    let circles: [InterestCircle]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PlatformMetrics.cardFooterSpacing) {
                ForEach(circles) { circle in
                    NavigationLink(value: CircleBrowseRoute.circle(circle)) {
                        clubPosterLabel(circle)
                            .platformPosterRailFrame()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, PlatformMetrics.minContentGap)
        }
    }

    private func clubPosterLabel(_ circle: InterestCircle) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: PlatformMetrics.radiusPoster, style: .continuous)
                .fill(Color.accentColor.opacity(0.14))
                .overlay {
                    Image(systemName: circle.systemImage)
                        .font(.largeTitle)
                        .platformSymbolStyle(.multicolor)
                }
                .aspectRatio(PlatformMetrics.posterCardAspectRatio, contentMode: .fit)
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: PlatformMetrics.minContentGap) {
                Text(circle.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text("\(circle.topic) · \(circle.memberCount) 人")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(PlatformMetrics.captionBadgeInset)
            .colorScheme(.dark)
        }
        .clipShape(PlatformMetrics.posterShape)
        .contentShape(PlatformMetrics.posterShape)
        .accessibilityLabel("\(circle.name)，\(circle.topic)，\(circle.memberCount) 成员")
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
