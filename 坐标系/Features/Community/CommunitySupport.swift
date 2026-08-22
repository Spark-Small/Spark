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
    let id = UUID()
    let photos: [CommunityPhotoRef]
    let startIndex: Int
}

// MARK: - Rows

enum CommunityCommentRowStyle {
    /// 社区 Feed / 详情嵌入
    case feed
    /// 评论 Sheet / 楼中楼：主楼大头像 + 回复小头像 + 三级信息行
    case thread
    /// Form / List 系统行
    case form
}

struct CommunityCommentRow: View {
    let comment: CommunityComment
    var style: CommunityCommentRowStyle = .feed
    var isReply = false
    var allowsTextSelection = false
    var showsLike = true
    var isLiked = false
    var isDisliked = false
    var showsTranslate = true
    var contentOwnerName: String? = nil
    var ownerBadgeTitle = "作者"
    var onLike: (() -> Void)? = nil
    var onDislike: (() -> Void)? = nil
    var onReply: (() -> Void)? = nil
    var onTranslate: (() -> Void)? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isContentOwner: Bool {
        guard let contentOwnerName else { return false }
        return comment.author == contentOwnerName
    }

    var body: some View {
        switch style {
        case .feed:
            feedBody
        case .thread:
            threadBody
        case .form:
            formBody
        }
    }

    private var avatarSide: CGFloat {
        switch style {
        case .thread:
            isReply
                ? dynamicTypeSize.commentThreadReplyAvatarSide
                : dynamicTypeSize.commentThreadRootAvatarSide
        case .feed, .form:
            dynamicTypeSize.listAvatarSide
        }
    }

    private var threadLeadingInset: CGFloat {
        isReply ? dynamicTypeSize.commentThreadReplyLeadingInset : 0
    }

    private var feedBody: some View {
        HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
            PlatformListAvatarView(name: comment.author, side: avatarSide)

            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                authorTimeLine
                commentText
                actionRow
            }
        }
    }

    private var threadBody: some View {
        HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
            PlatformListAvatarView(name: comment.author, side: avatarSide)

            VStack(alignment: .leading) {
                threadAuthorLine
                commentText
                threadMetadataRow
            }
        }
        .padding(.leading, threadLeadingInset)
    }

    private var formBody: some View {
        VStack(alignment: .leading) {
            formMetadataLine
            commentText
            actionRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var commentText: some View {
        Group {
            if allowsTextSelection {
                Text(comment.text)
                    .textSelection(.enabled)
            } else {
                Text(comment.text)
            }
        }
        .font(commentTextFont)
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var commentTextFont: Font {
        switch style {
        case .form, .thread:
            PlatformListTypography.body
        case .feed:
            .body
        }
    }

    private var threadAuthorLine: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(comment.author)
                .font(PlatformListTypography.secondary)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if isContentOwner {
                threadOwnerBadge
            }

            if let replyTo = comment.replyToAuthor, !replyTo.isEmpty, !isReply {
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(replyTo)
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var threadOwnerBadge: some View {
        Text(ownerBadgeTitle)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
            .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
            .background(PlatformStatus.danger, in: Capsule())
    }

    private var threadMetadataRow: some View {
        HStack(alignment: .center) {
            Text(Formatters.commentRelativeTime(from: comment.postedAt))
                .foregroundStyle(.tertiary)

            if let region = comment.region?.trimmingCharacters(in: .whitespacesAndNewlines), !region.isEmpty {
                Text("·")
                    .foregroundStyle(.quaternary)
                Text(region)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            if let onReply {
                Text("·")
                    .foregroundStyle(.quaternary)
                Button("回复", action: onReply)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if showsLike {
                PlatformCommentReactionButtons(
                    isLiked: isLiked,
                    isDisliked: isDisliked,
                    font: PlatformListTypography.footnote,
                    onLike: onLike,
                    onDislike: onDislike
                )
            }
        }
        .font(PlatformListTypography.footnote)
    }

    private var formMetadataLine: some View {
        HStack(alignment: .firstTextBaseline) {
            if let replyTo = comment.replyToAuthor, !replyTo.isEmpty {
                Text(comment.author)
                    .font(PlatformListTypography.primary)
                    .lineLimit(1)
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(replyTo)
                    .font(PlatformListTypography.primary)
                    .lineLimit(1)
            } else {
                Text(comment.author)
                    .font(PlatformListTypography.primary)
                    .lineLimit(1)
            }

            if isContentOwner {
                Text(ownerBadgeTitle)
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(Formatters.commentRelativeTime(from: comment.postedAt))
                .font(PlatformListTypography.footnote)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    private var authorTimeLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: PlatformMetrics.detailMicroSpacing) {
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

            if isContentOwner {
                Text(ownerBadgeTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(Formatters.commentRelativeTime(from: comment.postedAt))
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
    }

    private var actionRow: some View {
        HStack {
            if let onReply {
                Button("回复", action: onReply)
                    .buttonStyle(.borderless)
            }
            if showsTranslate, style == .feed {
                Button("查看翻译") {
                    onTranslate?()
                }
                .buttonStyle(.borderless)
            }
            Spacer(minLength: 0)
            if showsLike {
                PlatformCommentReactionButtons(
                    isLiked: isLiked,
                    isDisliked: isDisliked,
                    font: style == .form ? PlatformListTypography.footnote : .subheadline,
                    multicolorLike: style != .form,
                    onLike: onLike,
                    onDislike: onDislike
                )
            }
        }
        .foregroundStyle(.secondary)
    }
}

/// Feed 卡片：作者行下方的正文展示（话题内联）。
struct CommunityPostFeedText: View {
    let post: CommunityPost

    var body: some View {
        Text("\(post.messageText)\(inlineTagsString)")
            .font(PlatformListTypography.body)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inlineTagsString: AttributedString {
        CommunityInlineTags.attributedTags(post.tags)
    }
}

/// 详情页正文 + 标签（话题内联在正文末尾，蓝色可点击）。
struct CommunityPostBodySection: View {
    let post: CommunityPost
    var onTagTapped: ((String) -> Void)?

    var body: some View {
        Text("\(post.messageText)\(inlineTagsString)")
            .font(PlatformListTypography.body)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inlineTagsString: AttributedString {
        CommunityInlineTags.attributedTags(post.tags)
    }
}

private enum CommunityInlineTags {
    static func attributedTags(_ tags: [String]) -> AttributedString {
        var result = AttributedString()
        for tag in tags {
            var chunk = AttributedString(" #\(tag)")
            chunk.foregroundColor = .accentColor
            result.append(chunk)
        }
        return result
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
        communityQuickLook(destination)
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
            CommunityShareSheet(postID: postID)
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
