//
//  CommunityPostCard.swift
//  坐标系
//
//  信息流卡：作者行 → 正文 → 媒体 → 互动（feed / teaser 同骨架）。
//  媒体：系统 TabView 分页左右滑；双击点赞走官方 SF Symbol bounce + platformStateFeedback（无自绘大心）。
//  单点进详情走正文 / a11y；媒体不进全屏预览。
//

import SwiftUI
import CoordinateModels

enum CommunityPostCardStyle: Equatable {
    /// 主 Feed
    case feed
    /// 「为你推荐」轨：与主 Feed 同骨架；Section 头提供语境，不再内嵌「推荐分享」字样。
    case teaser
}

struct CommunityPostCard: View {
    let post: CommunityPost
    var style: CommunityPostCardStyle = .feed
    /// 仅推荐轨：长按 / 辅助功能「少看这类分享」（对齐 Music Suggest Less）。
    var onSuggestLess: (() -> Void)? = nil

    @Environment(BuddiesModel.self) private var buddies

    @State private var authorDestination: CommunityAuthorDestination?
    /// 双击媒体与赞按钮共用；驱动 `symbolEffect(.bounce)`（WWDC23）。
    @State private var likeFeedbackPulse = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CommunityPostAuthorHeader(post: post) {
                authorDestination = buddies.authorDestination(for: post.author)
            }

            if !post.messageText.isEmpty {
                NavigationLink(value: post) {
                    CommunityPostFeedText(post: post)
                }
                .buttonStyle(.plain)
                .communityRowToContentSpacing()
            }

            if !post.displayPhotos.isEmpty {
                CommunityPostFeedMedia(post: post, likeFeedbackPulse: $likeFeedbackPulse)
                    .communityRowToContentSpacing()
            } else if post.messageText.isEmpty {
                NavigationLink(value: post) {
                    Text(CommunityBrowseCopy.viewShare)
                        .font(PlatformListTypography.secondary)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .communityRowToContentSpacing()
            }

            CommunityPostActionBar(post: post, likeFeedbackPulse: $likeFeedbackPulse)
                .communityRowToContentSpacing()
        }
        .communityFeedCardTailSpacing()
        .communityAuthorSheet($authorDestination)
        .modifier(CommunityPostSuggestLessChrome(onSuggestLess: onSuggestLess))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var parts = [post.author]
        if style == .teaser {
            parts.append(CommunityDynamicsCopy.recommendedForYou)
        }
        let body = post.messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !body.isEmpty {
            parts.append(body)
        }
        if !post.displayPhotos.isEmpty {
            parts.append(CommunityBrowseCopy.mediaPhotosAccessibility(count: post.displayPhotos.count))
        }
        return parts.joined(separator: "，")
    }
}

/// Feed 媒体：分页滑动 + 双击点赞（反馈落到互动栏爱心，对齐活动收藏）。
private struct CommunityPostFeedMedia: View {
    let post: CommunityPost
    @Binding var likeFeedbackPulse: Int

    @Environment(CommunityModel.self) private var model

    private var photos: [CommunityPhotoRef] { post.displayPhotos }

    var body: some View {
        CommunityMediaPager(pageCount: photos.count) { index in
            CommunityRemotePhoto(ref: photos[index])
                .onTapGesture(count: 2, perform: doubleTapLike)
        }
        .clipShape(CommunityLayout.mediaShape)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: Text(CommunityEngagementCopy.like), doubleTapLike)
        .accessibilityHint(CommunityBrowseCopy.feedMediaDoubleTapLikeHint)
    }

    private func doubleTapLike() {
        if !model.isLiked(post.id) {
            model.toggleLike(post.id)
        }
        likeFeedbackPulse += 1
    }
}

private struct CommunityPostSuggestLessChrome: ViewModifier {
    var onSuggestLess: (() -> Void)?

    func body(content: Content) -> some View {
        if let onSuggestLess {
            content
                .contextMenu {
                    Button(CommunityDynamicsCopy.suggestLess, systemImage: "hand.thumbsdown") {
                        onSuggestLess()
                    }
                }
                .accessibilityAction(named: Text(CommunityDynamicsCopy.suggestLess)) {
                    onSuggestLess()
                }
        } else {
            content
        }
    }
}

/// Feed 行：按帖子身份与互动态稳定差分，减少 List 无差别整表刷新（P11）。
struct CommunityFeedPostRow: View, Equatable {
    let post: CommunityPost
    let isLiked: Bool
    let isBookmarked: Bool
    let isReposted: Bool
    let isFollowingAuthor: Bool

    var body: some View {
        CommunityPostCard(post: post)
    }

    static func == (lhs: CommunityFeedPostRow, rhs: CommunityFeedPostRow) -> Bool {
        lhs.post.id == rhs.post.id
            && lhs.post.likeCount == rhs.post.likeCount
            && lhs.post.commentCount == rhs.post.commentCount
            && lhs.post.repostCount == rhs.post.repostCount
            && lhs.post.shareCount == rhs.post.shareCount
            && lhs.post.messageText == rhs.post.messageText
            && lhs.post.postedAt == rhs.post.postedAt
            && lhs.post.isPinned == rhs.post.isPinned
            && lhs.post.displayPhotos.count == rhs.post.displayPhotos.count
            && lhs.post.relatedActivityID == rhs.post.relatedActivityID
            && lhs.isLiked == rhs.isLiked
            && lhs.isBookmarked == rhs.isBookmarked
            && lhs.isReposted == rhs.isReposted
            && lhs.isFollowingAuthor == rhs.isFollowingAuthor
    }
}
