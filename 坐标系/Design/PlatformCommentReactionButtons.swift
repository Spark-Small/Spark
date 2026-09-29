//
//  PlatformCommentReactionButtons.swift
//  坐标系
//
//  评论点赞 / 回复操作条。
//

import SwiftUI

// MARK: - Reactions

struct PlatformCommentReactionButtons: View {
    var isLiked: Bool
    var isDisliked: Bool
    var font: Font = PlatformListTypography.footnote
    var multicolorLike = true
    var onLike: (() -> Void)? = nil
    var onDislike: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
            reactionButton(
                title: "不喜欢",
                filledSystemName: "hand.thumbsdown.fill",
                outlineSystemName: "hand.thumbsdown",
                isActive: isDisliked,
                activeColor: .secondary,
                multicolor: false,
                action: onDislike
            )
            reactionButton(
                title: "赞",
                filledSystemName: "heart.fill",
                outlineSystemName: "heart",
                isActive: isLiked,
                activeColor: PlatformStatus.danger,
                multicolor: multicolorLike,
                action: onLike
            )
        }
        .font(font)
    }

    @ViewBuilder
    private func reactionButton(
        title: String,
        filledSystemName: String,
        outlineSystemName: String,
        isActive: Bool,
        activeColor: Color,
        multicolor: Bool,
        action: (() -> Void)?
    ) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: isActive ? filledSystemName : outlineSystemName)
                .symbolRenderingMode(multicolor ? .multicolor : .monochrome)
                .foregroundStyle(isActive ? activeColor : .secondary)
        }
        .buttonStyle(.borderless)
        .controlSize(.regular)
        .disabled(action == nil)
        .accessibilityLabel(isActive ? "取消\(title)" : title)
    }
}

