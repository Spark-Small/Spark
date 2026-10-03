//
//  CommunityPostActionBar.swift
//  坐标系
//
//  信息流操作：赞（点按 / 媒体双击共用 bounce 反馈）/ 评论 / 分享 / 收藏。
//  发布时间在作者副文（`CommunityPostAuthorHeader`），不挂互动栏。
//

import SwiftUI
import CoordinateModels

struct CommunityPostActionBar: View {
    let post: CommunityPost
    /// 详情页内嵌评论时隐藏「评论」入口，避免与底栏输入重复。
    var showsCommentEntry = true
    /// Feed 卡传入：媒体双击与赞按钮共用；详情可省略（用本地 pulse）。
    var likeFeedbackPulse: Binding<Int>? = nil

    @Environment(CommunityModel.self) private var model
    @State private var activeSheet: CommunityActionSheet?
    @State private var localLikePulse = 0

    private var livePost: CommunityPost {
        model.post(id: post.id) ?? post
    }

    private var isLiked: Bool { model.isLiked(post.id) }
    private var isBookmarked: Bool { model.isBookmarked(post.id) }

    private var likePulse: Binding<Int> {
        likeFeedbackPulse ?? $localLikePulse
    }

    var body: some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            likeButton

            if showsCommentEntry {
                actionButton(
                    systemImage: "bubble.right",
                    count: livePost.commentCount,
                    accessibilityLabel: CommunityEngagementCopy.comment
                ) { activeSheet = .comments }
            }

            actionButton(
                systemImage: "paperplane",
                count: livePost.shareCount + livePost.repostCount,
                accessibilityLabel: CommunityEngagementCopy.share
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
            .accessibilityLabel(
                isBookmarked
                    ? CommunityEngagementCopy.unbookmark
                    : CommunityEngagementCopy.bookmark
            )
        }
        .sensoryFeedback(.selection, trigger: isBookmarked)
        .sheet(item: $activeSheet) { sheet in
            sheet.sheet(postID: post.id)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
    }

    private var likeButton: some View {
        Button {
            likePulse.wrappedValue += 1
            model.toggleLike(post.id)
        } label: {
            HStack(
                alignment: .center,
                spacing: PlatformListActionSymbol.trailingTextSpacing
            ) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .platformListActionSymbolStyle(
                        isActive: isLiked,
                        activeColor: PlatformStatus.danger
                    )
                    .symbolEffect(.bounce, value: likePulse.wrappedValue)
                Text(Formatters.compactCount(livePost.likeCount))
                    .font(PlatformListActionSymbol.countFont)
                    .foregroundStyle(isLiked ? PlatformStatus.danger : .secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .buttonStyle(.borderless)
        .platformStateFeedback(likePulse)
        .accessibilityLabel(
            CommunityEngagementCopy.actionCountLabel(
                isLiked ? CommunityEngagementCopy.unlike : CommunityEngagementCopy.like,
                count: livePost.likeCount
            )
        )
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
        .accessibilityLabel(CommunityEngagementCopy.actionCountLabel(accessibilityLabel, count: count))
    }
}
