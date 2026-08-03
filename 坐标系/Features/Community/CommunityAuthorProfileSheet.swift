//
//  CommunityAuthorProfileSheet.swift
//  坐标系
//

import SwiftUI

struct CommunityAuthorFallbackSheet: View {
    let name: String
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var showReport = false
    @State private var confirmBlock = false

    private var profile: AuthorDirectoryProfile { SampleData.author(named: name) }

    private var hostedActivities: [Activity] {
        SampleData.activities.filter { $0.hostName == name }.prefix(3).map { $0 }
    }

    private var recentPosts: [CommunityPost] {
        SampleData.posts.filter { $0.author == name }.prefix(3).map { $0 }
    }

    private var buddyMatch: DiscoverBuddyItem? {
        if let paid = SampleData.paidCompanions.first(where: { $0.profile.nickname == name }) {
            return .paid(paid)
        }
        if let free = SampleData.circleBuddies.first(where: { $0.profile.nickname == name }) {
            return .free(free)
        }
        return nil
    }

    var body: some View {
        let flags = TrustPublicCredentials.flags(
            nickname: name,
            currentUserName: app.user.name,
            buddyItem: buddyMatch,
            membershipActive: false
        )
        MessagesFormSheet(title: "作者资料") {
            List {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                            Text(profile.name)
                                .font(.title3.bold())
                            Text(profile.roleLabel)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text(profile.city)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            TrustCredentialBadgeStrip(
                                photoVerified: flags.photoVerified,
                                isMember: flags.isMember,
                                revealLocked: false
                            )
                        }
                    } icon: {
                        PlatformSystemAvatar(side: PlatformConversationListRow.imageSide)
                    }

                    Text(profile.bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !profile.tags.isEmpty {
                        CommunityTagsLine(tags: profile.tags)
                    }

                    HStack {
                        labeledStat(title: "发起", value: "\(profile.hostedCount)")
                        Spacer()
                        labeledStat(title: "参加", value: "\(profile.joinedCount)")
                        Spacer()
                        labeledStat(title: "分享", value: "\(recentPosts.count)")
                    }
                }

                TrustPublicProfileSections(
                    nickname: name,
                    currentUserName: app.user.name,
                    buddyItem: buddyMatch,
                    compact: true
                )

                if !hostedActivities.isEmpty {
                    Section("TA 发起的活动") {
                        ForEach(hostedActivities) { activity in
                            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                                Text(activity.title)
                                    .font(.subheadline.weight(.semibold))
                                Text("\(activity.location) · \(activity.fee)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !recentPosts.isEmpty {
                    Section("最近分享") {
                        ForEach(recentPosts) { post in
                            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                                Text(post.messageText)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(3)
                            }
                        }
                    }
                }

                Section {
                    Button("发私聊") {
                        if let convo = app.startDirectChat(with: name) {
                            dismiss()
                            app.openMessages(conversationID: convo.id)
                        }
                    }
                    if buddyMatch != nil {
                        Button("查看搭子主页") {
                            dismiss()
                            app.selectedTab = .buddies
                        }
                    }
                    Button("举报", role: .destructive) {
                        showReport = true
                    }
                    Button("拉黑", role: .destructive) {
                        confirmBlock = true
                    }
                }
            }
        }
        .alert(
            "举报 \(name)",
            isPresented: $showReport
        ) {
            ForEach(MessagesCopy.reportReasons, id: \.self) { reason in
                Button(reason, role: .destructive) {
                    app.addModerationTicket(
                        postID: UUID(),
                        title: name,
                        reason: reason,
                        targetKind: .person
                    )
                    dismiss()
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(MessagesCopy.reportFooter)
        }
        .alert(
            "拉黑 \(name)？",
            isPresented: $confirmBlock
        ) {
            Button("拉黑", role: .destructive) {
                app.blockUser(name)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("拉黑后将不再收到对方的互动与消息。")
        }
    }

    private func labeledStat(title: String, value: String) -> some View {
        VStack(spacing: PlatformMetrics.hairlineSpacing) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
