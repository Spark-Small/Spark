//
//  CommunityAuthorProfileSheet.swift
//  坐标系
//
//  作者 / 活动成员资料：可作 Sheet，也可作为 NavigationLink 目的地。
//

import SwiftUI
import CoordinateModels

/// 用户资料页（活动成员、社区作者等无完整搭子卡时的详情）。
struct CommunityAuthorProfileView: View {
    let name: String
    var chatContextOverride: ConversationChatContext? = nil
    var showsBuddyHomeShortcut = true

    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(CommunityModel.self) private var community
    @Environment(ActivitiesModel.self) private var activities
    @Environment(\.dismiss) private var dismiss
    @State private var showReport = false
    @State private var confirmBlock = false
    @State private var peerContactRoute: PeerContactRoute?

    /// 仅本机 / 目录匹配；不直读 Sample 名单灌假卡。
    private var buddyMatch: DiscoverBuddyItem? {
        buddies.item(for: name)
    }

    private var hostedActivities: [Activity] {
        activities.activities
            .filter { $0.hostName.caseInsensitiveCompare(name) == .orderedSame }
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { $0 }
    }

    private var hasRecentPosts: Bool {
        community.items.contains {
            $0.author.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    private var displayCity: String {
        buddyMatch?.profile.city.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var displayBio: String {
        buddyMatch?.profile.bio.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var displayTags: [String] {
        buddyMatch?.profile.tags ?? []
    }

    private var roleLabel: String {
        switch buddyMatch {
        case .paid:
            CommunityAuthorCopy.roleCompanion
        case .free:
            CommunityAuthorCopy.roleBuddy
        case nil:
            if !hostedActivities.isEmpty {
                CommunityAuthorCopy.roleHost
            } else if hasRecentPosts {
                CommunityAuthorCopy.roleAuthor
            } else {
                CommunityAuthorCopy.roleUser
            }
        }
    }

    var body: some View {
        let flags = TrustPublicCredentials.flags(
            nickname: name,
            currentUserName: app.user.name,
            buddyItem: buddyMatch,
            membershipActive: false,
            verificationPhotos: name.caseInsensitiveCompare(app.user.name) == .orderedSame
                ? app.user.verificationPhotos
                : []
        )
        List {
            Section {
                VStack {
                    HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
                        Label {
                            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                                Text(name)
                                    .font(PlatformListTypography.title3Emphasized)
                                Text(roleLabel)
                                    .font(PlatformListTypography.captionEmphasized)
                                    .foregroundStyle(.secondary)
                                if !displayCity.isEmpty {
                                    Text(displayCity)
                                        .font(PlatformListTypography.caption)
                                        .foregroundStyle(.tertiary)
                                }
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

                if !displayBio.isEmpty {
                    Text(displayBio)
                        .font(PlatformListTypography.secondary)
                        .foregroundStyle(.secondary)
                }

                if !displayTags.isEmpty {
                    CommunityTagsLine(tags: displayTags)
                }
            }

            TrustPublicProfileSections(
                nickname: name,
                currentUserName: app.user.name,
                buddyItem: buddyMatch,
                compact: true
            )

            if !hostedActivities.isEmpty {
                Section(CommunityAuthorCopy.hostedSection) {
                    ForEach(hostedActivities) { activity in
                        CommunityHostedActivityLinkRow(activity: activity)
                    }
                }
            }

            CommunityAuthorRecentPostsSection(authorName: name)

            Section {
                Button(CommunityAuthorCopy.report, role: .destructive) {
                    showReport = true
                }
                Button(CommunityAuthorCopy.block, role: .destructive) {
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
            CommunityAuthorCopy.reportTitle(name),
            isPresented: $showReport
        ) {
            ForEach(CommunityBrowseCopy.reportReasons, id: \.self) { reason in
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
            Button(CommunityAuthorCopy.cancel, role: .cancel) {}
        } message: {
            Text(CommunityBrowseCopy.reportFooter)
        }
        .alert(
            CommunityAuthorCopy.blockConfirmTitle(name),
            isPresented: $confirmBlock
        ) {
            Button(CommunityAuthorCopy.block, role: .destructive) {
                app.blockUser(name)
                dismiss()
            }
            Button(CommunityAuthorCopy.cancel, role: .cancel) {}
        } message: {
            Text(CommunityAuthorCopy.blockConfirmMessage)
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
                    Text(CommunityBrowseCopy.openBuddyProfile)
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
            Text(following ? CommunityDynamicsCopy.following : CommunityDynamicsCopy.follow)
        }
        .modifier(CommunityFollowButtonChrome(following: following))
        .sensoryFeedback(.selection, trigger: following)
        .accessibilityLabel(
            following
                ? "\(CommunityDynamicsCopy.following)，\(name)"
                : "\(CommunityDynamicsCopy.follow)，\(name)"
        )
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
