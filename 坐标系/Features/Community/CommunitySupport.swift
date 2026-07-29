//
//  CommunitySupport.swift
//  坐标系
//
//  社区模块共享路由、行组件与 Sheet 修饰。
//

import SwiftUI

// MARK: - Routes

enum CommunityAuthorDestination: Identifiable {
    case buddy(DiscoverBuddyItem)
    case fallback(String)

    var id: String {
        switch self {
        case .buddy(let item): "buddy-\(item.id)"
        case .fallback(let name): "fallback-\(name)"
        }
    }
}

struct CommunityPhotoDestination: Identifiable {
    let photos: [CommunityPhotoRef]
    let startIndex: Int

    var id: Int { startIndex }
}

// MARK: - Rows

struct CommunityCommentRow: View {
    let comment: CommunityComment
    var allowsTextSelection = false
    var showsLike = true
    var isLiked = false
    var showsTranslate = true
    var onLike: (() -> Void)? = nil
    var onReply: (() -> Void)? = nil
    var onTranslate: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
            PlatformListAvatarView(name: comment.author)

            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                authorTimeLine

                Group {
                    if allowsTextSelection {
                        Text(comment.text)
                            .textSelection(.enabled)
                    } else {
                        Text(comment.text)
                    }
                }
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

                actionRow
            }

            if showsLike {
                likeColumn
            }
        }
    }

    private var authorTimeLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let replyTo = comment.replyToAuthor, !replyTo.isEmpty {
                Text(comment.author)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(replyTo)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            } else {
                Text(comment.author)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Text(Formatters.commentRelativeTime(from: comment.postedAt))
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            if let onReply {
                Button("回复", action: onReply)
                    .buttonStyle(.plain)
            }
            if showsTranslate {
                Button("查看翻译") {
                    onTranslate?()
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .font(.subheadline)
        .foregroundStyle(.tertiary)
    }

    private var likeColumn: some View {
        Button {
            onLike?()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.body)
                    .foregroundStyle(isLiked ? PlatformStatus.danger : .secondary)
                if comment.likeCount > 0 {
                    Text("\(comment.likeCount)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .frame(minWidth: 28)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(isLiked ? "取消赞" : "赞")
    }
}

/// Feed 卡片：作者行下方的正文展示。
struct CommunityPostFeedText: View {
    let post: CommunityPost

    var body: some View {
        Text(post.messageText)
            .font(PlatformListTypography.body)
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 详情页正文 + 标签。
struct CommunityPostBodySection: View {
    let post: CommunityPost

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
            Text(post.messageText)
                .font(PlatformListTypography.body)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !post.tags.isEmpty {
                CommunityTagsLine(tags: post.tags)
            }
        }
    }
}

/// 系统 footnote 标签行（无自定义胶囊）。
struct CommunityTagsLine: View {
    let tags: [String]

    var body: some View {
        Text(tags.joined(separator: " · "))
            .font(PlatformListTypography.footnote)
            .foregroundStyle(.secondary)
    }
}

/// Feed / 详情共用作者行。
struct CommunityPostAuthorHeader: View {
    let post: CommunityPost
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            PlatformListAuthorLine(
                name: post.author,
                time: post.postedAt,
                isPinned: post.isPinned
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("查看作者资料")
    }
}

struct CommunityRelatedActivityLink: View {
    let activity: Activity
    var showsEventTime = false

    var body: some View {
        NavigationLink(value: activity) {
            HStack(
                alignment: showsEventTime ? .top : .center,
                spacing: PlatformConversationListRow.imageToTextPadding
            ) {
                PlatformListSymbolAvatar(
                    systemName: activity.category.systemImage,
                    side: PlatformConversationListRow.imageSide
                )

                Group {
                    if showsEventTime {
                        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                            Text("来自 · \(activity.title)")
                            Text(Formatters.activityEventTime(from: activity.date))
                                .font(PlatformListTypography.trailing)
                        }
                    } else {
                        Text("来自 · \(activity.title)")
                            .lineLimit(1)
                    }
                }
                .font(PlatformListTypography.secondary)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Presentation

extension View {
    func communityAuthorSheet(_ destination: Binding<CommunityAuthorDestination?>) -> some View {
        sheet(item: destination) { route in
            switch route {
            case .buddy(let item):
                NavigationStack {
                    BuddyDetailRouteView(item: item)
                }
                .platformSheet(.browser)
            case .fallback(let name):
                CommunityAuthorFallbackSheet(name: name)
            }
        }
    }

    func communityPhotoCover(_ destination: Binding<CommunityPhotoDestination?>) -> some View {
        fullScreenCover(item: destination) { route in
            CommunityPhotoViewer(photos: route.photos, startIndex: route.startIndex)
        }
    }
}

extension CommunityActionSheet {
    @ViewBuilder
    func sheet(postID: CommunityPost.ID) -> some View {
        switch self {
        case .likes:
            CommunityLikesSheet(postID: postID)
        case .comments:
            CommunityCommentsSheet(postID: postID)
        case .repost:
            CommunityRepostSheet(postID: postID)
        case .send:
            CommunitySendSheet(postID: postID)
        case .bookmark:
            CommunityBookmarkSheet(postID: postID)
        }
    }
}

extension BuddiesModel {
    func authorDestination(for name: String) -> CommunityAuthorDestination {
        if let item = item(for: name) {
            .buddy(item)
        } else {
            .fallback(name)
        }
    }
}
