//
//  CommunityCrossModuleLinks.swift
//  坐标系
//
//  广场 ↔ 活动 / 帖详情的可点行（作者资料、搭子详情复用）。
//

import SwiftUI
import CoordinateModels

struct CommunityHostedActivityLinkRow: View {
    let activity: Activity

    var body: some View {
        NavigationLink {
            ActivityDetailView(activity: activity)
                .toolbarVisibility(.hidden, for: .tabBar)
        } label: {
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(activity.title)
                    .font(PlatformListTypography.secondaryEmphasized)
                Text("\(activity.location) · \(activity.fee)")
                    .font(PlatformListTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CommunityRecentPostLinkRow: View {
    let post: CommunityPost

    var body: some View {
        NavigationLink {
            CommunityPostDetailView(postID: post.id)
                .toolbarVisibility(.hidden, for: .tabBar)
        } label: {
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(post.messageText.isEmpty ? CommunityBrowseCopy.viewShare : post.messageText)
                    .font(PlatformListTypography.secondaryEmphasized)
                    .lineLimit(3)
                    .foregroundStyle(.primary)
                Text(Formatters.conversationListTime(from: post.postedAt))
                    .font(PlatformListTypography.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .accessibilityLabel(
                        CommunityEngagementCopy.postedAtAccessibility(
                            Formatters.conversationListTime(from: post.postedAt)
                        )
                    )
            }
        }
    }
}

/// 搭子 / 作者资料：最近广场分享（最多 3 条）。
struct CommunityAuthorRecentPostsSection: View {
    let authorName: String
    var sectionTitle: String = CommunityAuthorCopy.recentPostsSection
    var showsEmptyState = false
    var emptyTitle: String = CommunityAuthorCopy.recentPostsEmptyTitle
    var emptyDescription: String = CommunityAuthorCopy.recentPostsEmptyDescription

    @Environment(CommunityModel.self) private var community

    private var recentPosts: [CommunityPost] {
        community.items
            .filter { $0.author.caseInsensitiveCompare(authorName) == .orderedSame }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        if !recentPosts.isEmpty {
            Section(sectionTitle) {
                ForEach(recentPosts) { post in
                    CommunityRecentPostLinkRow(post: post)
                }
            }
        } else if showsEmptyState {
            Section {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "text.bubble",
                    description: Text(emptyDescription)
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, PlatformMetrics.sectionSpacing)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }
}
