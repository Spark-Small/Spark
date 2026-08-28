//
//  CommunityPostActionBar.swift
//  坐标系
//
//  信息流操作：赞（点按切换）/ 评论 / 分享（唯一外发入口）/ 收藏。
//

import SwiftUI

struct CommunityPostActionBar: View {
    let post: CommunityPost
    /// 详情页内嵌评论时隐藏「评论」入口，避免与底栏输入重复。
    var showsCommentEntry = true

    @Environment(CommunityModel.self) private var model
    @State private var activeSheet: CommunityActionSheet?

    private var livePost: CommunityPost {
        model.post(id: post.id) ?? post
    }

    private var isLiked: Bool { model.isLiked(post.id) }
    private var isBookmarked: Bool { model.isBookmarked(post.id) }

    var body: some View {
        HStack {
            actionButton(
                systemImage: isLiked ? "heart.fill" : "heart",
                count: livePost.likeCount,
                isActive: isLiked,
                activeColor: PlatformStatus.danger,
                accessibilityLabel: isLiked ? "取消赞" : "赞"
            ) {
                model.toggleLike(post.id)
            }

            if showsCommentEntry {
                actionButton(
                    systemImage: "bubble.right",
                    count: livePost.commentCount,
                    accessibilityLabel: "评论"
                ) { activeSheet = .comments }
            }

            actionButton(
                systemImage: "paperplane",
                count: livePost.shareCount + livePost.repostCount,
                accessibilityLabel: "分享"
            ) { activeSheet = .share }

            Spacer(minLength: 0)

            Button {
                if isBookmarked {
                    model.removeBookmark(post.id)
                } else {
                    activeSheet = .bookmark
                }
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .platformListActionSymbolStyle(isActive: isBookmarked)
                    .symbolEffect(.bounce, value: isBookmarked)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(isBookmarked ? "取消收藏" : "收藏")
        }
        .sensoryFeedback(.selection, trigger: isLiked)
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
                    .symbolEffect(.bounce, value: isActive)
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
