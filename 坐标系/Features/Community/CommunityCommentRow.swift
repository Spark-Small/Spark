//
//  CommunityCommentRow.swift
//  坐标系
//
//  楼中楼 / Form 评论行（Sheet · 详情嵌入 · 活动评论共用）。
//

import SwiftUI
import CoordinateModels

enum CommunityCommentRowStyle {
    /// 评论 Sheet / 楼中楼：主楼大头像 + 回复小头像 + 三级信息行
    case thread
    /// Form / List 系统行
    case form
}

struct CommunityCommentRow: View {
    let comment: CommunityComment
    var style: CommunityCommentRowStyle = .thread
    var isReply = false
    var allowsTextSelection = false
    var showsLike = true
    var isLiked = false
    var isDisliked = false
    var contentOwnerName: String? = nil
    var ownerBadgeTitle = CommunityAuthorCopy.roleAuthor
    var onLike: (() -> Void)? = nil
    var onDislike: (() -> Void)? = nil
    var onReply: (() -> Void)? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isContentOwner: Bool {
        guard let contentOwnerName else { return false }
        return comment.author == contentOwnerName
    }

    var body: some View {
        switch style {
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
        case .form:
            dynamicTypeSize.listAvatarSide
        }
    }

    private var threadLeadingInset: CGFloat {
        isReply ? dynamicTypeSize.commentThreadReplyLeadingInset : 0
    }

    private var threadBody: some View {
        HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
            PlatformListAvatarView(name: comment.author, side: avatarSide)

            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                threadAuthorLine
                voiceChip
                if showsTextBody { commentText }
                threadMetadataRow
            }
        }
        .padding(.leading, threadLeadingInset)
    }

    private var formBody: some View {
        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
            formMetadataLine
            voiceChip
            if showsTextBody { commentText }
            actionRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var showsTextBody: Bool {
        let trimmed = comment.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if comment.voiceDuration != nil, trimmed == PlatformReviewsCopy.voicePlaceholder {
            return false
        }
        return true
    }

    @ViewBuilder
    private var voiceChip: some View {
        if let duration = comment.voiceDuration, duration > 0 {
            PlatformVoiceNoteChip(
                fileURL: comment.voiceLocalName.flatMap(LocalMediaLibrary.fileURL(named:)),
                duration: duration
            )
        }
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
        .font(PlatformListTypography.body)
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var threadAuthorLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: PlatformConversationListRow.textToSecondarySpacing) {
            Text(comment.author)
                .font(PlatformListTypography.secondary)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if isContentOwner {
                threadOwnerBadge
            }

            if let replyTo = comment.replyToAuthor, !replyTo.isEmpty, !isReply {
                Image(systemName: "play.fill")
                    .font(PlatformListTypography.caption2)
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
            .font(PlatformListTypography.caption2Emphasized)
            .foregroundStyle(.white)
            .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
            .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
            .background(PlatformStatus.danger, in: Capsule())
    }

    private var threadMetadataRow: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.hairlineSpacing) {
            Text(Formatters.commentRelativeTime(from: comment.postedAt))
                .foregroundStyle(.tertiary)
                .monospacedDigit()

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
                Button(PlatformReviewsCopy.reply, action: onReply)
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
        HStack(alignment: .firstTextBaseline, spacing: PlatformConversationListRow.textToSecondarySpacing) {
            if let replyTo = comment.replyToAuthor, !replyTo.isEmpty {
                Text(comment.author)
                    .font(PlatformListTypography.primary)
                    .lineLimit(1)
                Image(systemName: "play.fill")
                    .font(PlatformListTypography.caption2)
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
                .monospacedDigit()
                .lineLimit(1)
        }
    }

    private var actionRow: some View {
        HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
            if let onReply {
                Button(PlatformReviewsCopy.reply, action: onReply)
                    .buttonStyle(.borderless)
            }
            Spacer(minLength: 0)
            if showsLike {
                PlatformCommentReactionButtons(
                    isLiked: isLiked,
                    isDisliked: isDisliked,
                    font: PlatformListTypography.footnote,
                    multicolorLike: false,
                    onLike: onLike,
                    onDislike: onDislike
                )
            }
        }
        .foregroundStyle(.secondary)
    }
}
