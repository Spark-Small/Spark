//
//  CommunityPostActionBar.swift
//  坐标系
//

import SwiftUI

struct CommunityPostActionBar: View {
    let post: CommunityPost

    @Environment(CommunityModel.self) private var model
    @State private var activeSheet: CommunityActionSheet?

    private var livePost: CommunityPost {
        model.post(id: post.id) ?? post
    }

    private var isLiked: Bool { model.isLiked(post.id) }
    private var isReposted: Bool { model.isReposted(post.id) }
    private var isBookmarked: Bool { model.isBookmarked(post.id) }

    var body: some View {
        HStack {
            actionButton(
                systemImage: isLiked ? "heart.fill" : "heart",
                count: livePost.likeCount,
                isActive: isLiked,
                activeColor: PlatformStatus.danger,
                accessibilityLabel: "赞"
            ) { activeSheet = .likes }

            actionButton(
                systemImage: "bubble.right",
                count: livePost.commentCount,
                accessibilityLabel: "评论"
            ) { activeSheet = .comments }

            actionButton(
                systemImage: "arrow.2.squarepath",
                count: livePost.repostCount,
                isActive: isReposted,
                accessibilityLabel: "转发"
            ) { activeSheet = .repost }

            actionButton(
                systemImage: "paperplane",
                count: livePost.shareCount,
                accessibilityLabel: "发送"
            ) { activeSheet = .send }

            Spacer(minLength: 0)

            Button { activeSheet = .bookmark } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .platformListActionSymbolStyle(isActive: isBookmarked)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("收藏")
        }
        .sensoryFeedback(.selection, trigger: isLiked)
        .sensoryFeedback(.selection, trigger: isReposted)
        .sensoryFeedback(.selection, trigger: isBookmarked)
        .sheet(item: $activeSheet) { sheet in
            sheet.sheet(postID: post.id)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
    }

    private func actionButton(
        systemImage: String,
        count: Int,
        isActive: Bool = false,
        activeColor: Color? = nil,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(
                alignment: .center,
                spacing: PlatformListActionSymbol.trailingTextSpacing
            ) {
                Image(systemName: systemImage)
                    .platformListActionSymbolStyle(isActive: isActive, activeColor: activeColor)
                Text(Formatters.compactCount(count))
                    .font(PlatformListActionSymbol.countFont)
                    .foregroundStyle(isActive ? (activeColor ?? .primary) : .secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("\(accessibilityLabel)，\(Formatters.compactCount(count))")
    }
}
