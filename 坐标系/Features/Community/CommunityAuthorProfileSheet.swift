//
//  CommunityAuthorProfileSheet.swift
//  坐标系
//
//  作者 / 活动成员资料：可作 Sheet，也可作为 NavigationLink 目的地。
//

import SwiftUI

/// 用户资料页（活动成员、社区作者等无完整搭子卡时的详情）。
struct CommunityAuthorProfileView: View {
    let name: String
    var chatContextOverride: ConversationChatContext? = nil
    var showsBuddyHomeShortcut = true

    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(CommunityModel.self) private var community
    @Environment(\.dismiss) private var dismiss
    @State private var showReport = false
    @State private var confirmBlock = false
    @State private var peerContactRoute: PeerContactRoute?

    private var profile: AuthorDirectoryProfile { SampleData.author(named: name) }

    private var hostedActivities: [Activity] {
        SampleData.activities.filter { $0.hostName == name }.prefix(3).map { $0 }
    }

    private var recentPosts: [CommunityPost] {
        SampleData.posts.filter { $0.author == name }.prefix(3).map { $0 }
    }

    private var buddyMatch: DiscoverBuddyItem? {
        buddies.item(for: name)
            ?? SampleData.paidCompanions.first { $0.profile.nickname == name }.map(DiscoverBuddyItem.paid)
            ?? SampleData.circleBuddies.first { $0.profile.nickname == name }.map(DiscoverBuddyItem.free)
    }

    var body: some View {
        let flags = TrustPublicCredentials.flags(
            nickname: name,
            currentUserName: app.user.name,
            buddyItem: buddyMatch,
            membershipActive: false
        )
        List {
            Section {
                VStack {
                    HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
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
                                    isMember: false,
                                    revealLocked: false
                                )
                            }
                        } icon: {
                            PlatformListAvatarView(name: name)
                        }

                        Spacer(minLength: 0)
                        followButton
                    }

                    ProfileSocialStatsRow(
                        postCount: ProfileSocialStats.postCount(for: name, community: community),
                        followingCount: ProfileSocialStats.followingCount(for: name, app: app),
                        fansCount: ProfileSocialStats.fansCount(for: name, app: app)
                    )
                }

                Text(profile.bio)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !profile.tags.isEmpty {
                    CommunityTagsLine(tags: profile.tags)
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
                Button("举报", role: .destructive) {
                    showReport = true
                }
                Button("拉黑", role: .destructive) {
                    confirmBlock = true
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
        .platformDetailBottomBar {
            authorActionBar
        }
        .peerContactDestination(route: $peerContactRoute)
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

    private var chatContext: ConversationChatContext {
        if let chatContextOverride {
            return chatContextOverride
        }
        if let buddyMatch {
            return .forBuddyItem(buddyMatch)
        }
        return .communityAuthor
    }

    @ViewBuilder
    private var authorActionBar: some View {
        if showsBuddyHomeShortcut, let item = buddyMatch {
            DetailBottomActionBar {
                NavigationLink {
                    BuddyDetailRouteView(item: item)
                } label: {
                    Text(CommunityCopy.openBuddyProfile)
                }
                .activityDetailBottomSecondaryCTA()

                Button(app.peerContactActionTitle(for: name, context: chatContext)) {
                    peerContactRoute = app.openPeerContact(
                        with: name,
                        context: chatContext
                    )
                }
                .activityDetailBottomPrimaryCTA()
            }
        } else {
            DetailBottomActionBar {
                Button(app.peerContactActionTitle(for: name, context: chatContext)) {
                    peerContactRoute = app.openPeerContact(
                        with: name,
                        context: chatContext
                    )
                }
                .activityDetailBottomPrimaryCTA()
            }
        }
    }

    private var followButton: some View {
        let following = app.isFollowing(name)
        return Button {
            app.toggleFollow(name)
        } label: {
            Text(following ? "已关注" : "关注")
        }
        .modifier(FollowButtonChrome(following: following))
        .sensoryFeedback(.selection, trigger: following)
    }
}

private struct FollowButtonChrome: ViewModifier {
    var following: Bool

    func body(content: Content) -> some View {
        if following {
            content
                .activitySecondaryCTA(controlSize: .small)
        } else {
            content
                .activityPrimaryCTA(controlSize: .small)
        }
    }
}

struct CommunityAuthorFallbackSheet: View {
    let name: String

    var body: some View {
        MessagesFormSheet(title: name) {
            CommunityAuthorProfileView(name: name)
        }
    }
}
