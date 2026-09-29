//
//  PlatformMessagesChromeMetrics.swift
//  坐标系
//
//  消息线程间距 / 气泡形状 / 宽度布局。
//

import SwiftUI
import CoordinateModels

enum PlatformMessagesChrome {
    /// 气泡行间距 = 系统 subtitleCell 行垂直 margin
    static var threadSpacing: CGFloat { PlatformConversationListRow.verticalInset }
    static var clusterSpacing: CGFloat { PlatformMetrics.hairlineSpacing }
    /// 气泡列 ↔ 头像列 = 系统 subtitleCell imageToTextPadding
    static var bubbleAvatarSpacing: CGFloat { PlatformConversationListRow.imageToTextPadding }
    static var composerControlSize: ControlSize { .large }
    static var composerToolSpacing: CGFloat { PlatformMetrics.composerToolSpacing }
    static var composerFieldHorizontalPadding: CGFloat { PlatformMetrics.composerFieldHorizontalPadding }
    static var composerBarVerticalPadding: CGFloat { PlatformMetrics.composerBarVerticalPadding }
    static var composerInlineSpacing: CGFloat { PlatformMetrics.composerInlineSpacing }
    static var daySeparatorVerticalPadding: CGFloat { PlatformMetrics.sectionSubtitleSpacing }
    static var emptyVerticalPadding: CGFloat { PlatformMetrics.emptyStateVerticalPadding }
    static var senderNameSpacing: CGFloat { PlatformConversationListRow.textToSecondarySpacing }
    static var replyCardSpacing: CGFloat { PlatformMetrics.hairlineSpacing }
    /// 同发送者连续气泡的最大间隔（秒）
    static var clusterGap: TimeInterval { 120 }
    /// 超过该间隔插入居中时间（秒）——系统信息节奏
    static var timestampGap: TimeInterval { 300 }
    /// 气泡相对会话行可用宽度的封顶比例（不读 UIScreen）
    static var bubbleWidthRatio: CGFloat { 0.68 }
    static var imageBubbleWidthRatio: CGFloat { 0.68 * 0.85 }
    static func imageBubbleHeight(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        (dynamicTypeSize.listAvatarSide * 4).rounded(.toNearestOrAwayFromZero)
    }
    static var presenceDotSize: CGFloat { PlatformMetrics.messagePresenceDotSize }
    /// 气泡宽度提案缺失时的回退
    static var bubbleWidthFallback: CGFloat { 280 }
}

/// Apple 官方聊天气泡：`UnevenRoundedRectangle` + `padding(9)` + accent / systemGray5
/// （Build a SwiftUI chat app 文档范式）
enum PlatformChatBubbleShape {
    private static let outerRadius: CGFloat = 16
    private static let tailRadius: CGFloat = 4

    static func unevenRoundedRectangle(isMe: Bool) -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: isMe ? outerRadius : tailRadius,
            bottomLeadingRadius: outerRadius,
            bottomTrailingRadius: isMe ? tailRadius : outerRadius,
            topTrailingRadius: outerRadius,
            style: .continuous
        )
    }

    static func fillColor(isMe: Bool) -> Color {
        isMe ? Color.accentColor : Color(.systemGray5)
    }

    static func labelColor(isMe: Bool) -> Color {
        isMe ? Color.white : Color.primary
    }

    static func secondaryLabelColor(isMe: Bool) -> Color {
        isMe ? Color.white.opacity(0.85) : Color.secondary
    }
}

struct PlatformChatBubbleStyle: ViewModifier {
    var isMe: Bool

    func body(content: Content) -> some View {
        content
            .padding(9)
            .foregroundStyle(PlatformChatBubbleShape.labelColor(isMe: isMe))
            .background {
                PlatformChatBubbleShape.unevenRoundedRectangle(isMe: isMe)
                    .fill(PlatformChatBubbleShape.fillColor(isMe: isMe))
            }
    }
}

extension View {
    func platformChatBubbleStyle(isMe: Bool) -> some View {
        modifier(PlatformChatBubbleStyle(isMe: isMe))
    }
}

/// 按父容器提案宽度比例封顶，短内容仍 hug（替代 UIScreen.main）
struct PlatformMessageBubbleWidthLayout: Layout {
    var ratio: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let subview = subviews.first else { return .zero }
        let maxWidth = Self.cappedWidth(proposal: proposal, ratio: ratio)
        let child = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: proposal.height))
        return CGSize(width: min(child.width, maxWidth), height: child.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard let subview = subviews.first else { return }
        subview.place(
            at: bounds.origin,
            proposal: ProposedViewSize(width: bounds.width, height: bounds.height)
        )
    }

    private static func cappedWidth(proposal: ProposedViewSize, ratio: CGFloat) -> CGFloat {
        guard let width = proposal.width, width.isFinite, width > 0 else {
            return PlatformMessagesChrome.bubbleWidthFallback
        }
        return (width * ratio).rounded(.down)
    }
}

extension View {
    func platformMessageBubbleMaxWidth(ratio: CGFloat = PlatformMessagesChrome.bubbleWidthRatio) -> some View {
        PlatformMessageBubbleWidthLayout(ratio: ratio) { self }
    }

    func platformMessageThreadScrollMargins() -> some View {
        platformMessagePageMargins()
    }
}
