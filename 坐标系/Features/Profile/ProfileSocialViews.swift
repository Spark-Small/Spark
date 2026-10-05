//
//  ProfileSocialViews.swift
//  坐标系
//
//  活动邀约明细（通知深链；不挂「我的活动」Hub）。
//

import SwiftUI
import CoordinateModels

struct ProfileActivityInvitesView: View {
    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies

    var body: some View {
        Group {
            if buddies.inviteRecords.isEmpty {
                emptyContent
            } else {
                invitesList
            }
        }
        .navigationTitle(ProfileDashboardCopy.activityInvites)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var invitesList: some View {
        List {
            Section {
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
            } footer: {
                Text("邀约进度会出现在通知里；此处可查看全部记录。找新陪玩去「搭子」，好友聊天在「消息」。")
            }
        }
        .profileSecondaryListChrome()
    }

    private var emptyContent: some View {
        ProfileLibraryEmptyView(
            title: "还没有活动邀约",
            systemImage: "paperplane",
            description: "在搭子页邀请同好参加活动后，进度会出现在通知里。"
        ) {
            Button("去搭子看看") {
                app.pendingBuddiesRoute = .socialBrowse
                app.selectedTab = .buddies
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
