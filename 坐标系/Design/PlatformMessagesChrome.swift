//
//  PlatformMessagesChrome.swift
//  坐标系
//
//  消息线程 chrome：系统色 / glass + 气泡布局（禁止品牌皮肤）。
//

import SwiftUI

enum PlatformMessagesChrome {
    /// 气泡行间距 = 系统 subtitleCell 行垂直 margin
    static var threadSpacing: CGFloat { PlatformConversationListRow.verticalInset }
    static var clusterSpacing: CGFloat { PlatformMetrics.hairlineSpacing }
    /// 气泡列 ↔ 头像列 = 系统 subtitleCell imageToTextPadding
    static var bubbleAvatarSpacing: CGFloat { PlatformConversationListRow.imageToTextPadding }
    static var composerControlSize: ControlSize { .large }
    static var composerToolSpacing: CGFloat { PlatformMetrics.composerToolSpacing }
    static var composerFieldVerticalPadding: CGFloat { PlatformMetrics.composerFieldVerticalPadding }
    static var composerFieldHorizontalPadding: CGFloat { PlatformMetrics.composerFieldHorizontalPadding }
    static var composerToolHeightFallback: CGFloat { PlatformMetrics.composerToolHeightFallback }
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

private struct PlatformChatBubbleStyle: ViewModifier {
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
private struct PlatformMessageBubbleWidthLayout: Layout {
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

struct PlatformChatDaySeparator: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(.vertical, PlatformMessagesChrome.daySeparatorVerticalPadding)
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }
}

/// 系统提示小字（进群 / 退群等）
struct PlatformChatSystemTip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlatformMessagesChrome.daySeparatorVerticalPadding)
            .accessibilityLabel(text)
    }
}

struct PlatformChatEmptyThread: View {
    let peerName: String

    var body: some View {
        ContentUnavailableView {
            Label(MessagesCopy.emptyThreadTitle, systemImage: "hand.wave")
        } description: {
            Text(MessagesCopy.emptyThreadDescription(peerName: peerName))
        }
        .padding(.vertical, PlatformMessagesChrome.emptyVerticalPadding)
    }
}

/// 气泡展示：群聊对方头像 + 连续消息聚类（信息 App 范式）
struct PlatformChatBubbleChrome: Equatable {
    var showsSenderName: Bool
    var showsLeadingAvatar: Bool
    var showsTrailingAvatar: Bool
    var reservesLeadingAvatar: Bool
    var reservesTrailingAvatar: Bool
    var isClusterContinuation: Bool
    var isNotice: Bool
}

struct PlatformChatBubble: View {
    let text: String
    let sentAt: Date
    var sender: String?
    var isMe: Bool
    var chrome: PlatformChatBubbleChrome
    var message: ChatMessage? = nil
    var isLiked: Bool = false
    var replyToSender: String? = nil
    var replyToText: String? = nil
    var onTapAvatar: (() -> Void)? = nil
    var onDoubleTap: (() -> Void)? = nil
    var onOpenActivity: ((UUID) -> Void)? = nil
    var onOpenLink: ((String) -> Void)? = nil

    @Environment(MessagesModel.self) private var messagesModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showsTime = false

    private var kind: ChatMessageKind { message?.messageKind ?? .text }
    private var liked: Bool { message?.isLiked ?? isLiked }
    private var reaction: String? { message?.reaction }

    var body: some View {
        Group {
            if chrome.isNotice {
                noticeBody
            } else {
                bubbleBody
            }
        }
        .padding(
            .top,
            chrome.isClusterContinuation
                ? PlatformMessagesChrome.clusterSpacing
                : PlatformMessagesChrome.threadSpacing
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(MessagesCopy.bubbleA11yHint)
        .accessibilityAction(named: MessagesCopy.like) { onDoubleTap?() }
    }

    private var bubbleBody: some View {
        HStack(alignment: .bottom, spacing: PlatformMessagesChrome.bubbleAvatarSpacing) {
            leadingAvatarColumn
            VStack(alignment: isMe ? .trailing : .leading, spacing: PlatformMessagesChrome.senderNameSpacing) {
                if chrome.showsSenderName, let sender, !sender.isEmpty {
                    Text(sender)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, PlatformMetrics.hairlineSpacing)
                }
                bubbleStack
                    .onTapGesture(count: 2) { onDoubleTap?() }
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) { showsTime.toggle() }
                    }
                if let reaction, !reaction.isEmpty {
                    Text(reaction)
                        .font(.caption)
                        .padding(PlatformMetrics.hairlineSpacing)
                        .background(.regularMaterial, in: Capsule())
                }
                if showsTime || (isMe && message?.deliveryStatus == .read) {
                    HStack(spacing: PlatformMetrics.hairlineSpacing) {
                        if showsTime {
                            Text(Formatters.shortTime.string(from: sentAt))
                        }
                        if isMe, let status = message?.deliveryStatus {
                            Text(status == .read ? MessagesCopy.seenStatus : MessagesCopy.deliveredStatus)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }
            trailingAvatarColumn
        }
    }

    private var bubbleStack: some View {
        VStack(alignment: isMe ? .trailing : .leading, spacing: PlatformMessagesChrome.replyCardSpacing) {
            if let replyToText, !replyToText.isEmpty { replyQuote }
            payloadBody
                .overlay(alignment: isMe ? .bottomLeading : .bottomTrailing) {
                    if liked, reaction == nil {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(PlatformStatus.danger)
                            .padding(PlatformMetrics.hairlineSpacing)
                            .background(Color(.systemBackground), in: Circle())
                            .offset(y: PlatformMetrics.detailCompactSpacing)
                            .accessibilityHidden(true)
                    }
                }
        }
        .platformMessageBubbleMaxWidth()
    }

    @ViewBuilder
    private var payloadBody: some View {
        switch kind {
        case .text:
            Text(text)
                .font(.body)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
                .platformChatBubbleStyle(isMe: isMe)
        case .sticker:
            Text(text).font(.largeTitle).padding(PlatformMetrics.detailCompactSpacing)
        case .image:
            imageBubble
        case .voice:
            Label("\(Int(message?.voiceDuration ?? 1))\"", systemImage: "waveform")
                .font(.body)
                .platformChatBubbleStyle(isMe: isMe)
        case .location:
            Label(message?.locationName ?? text, systemImage: "mappin.and.ellipse")
                .font(.body)
                .platformChatBubbleStyle(isMe: isMe)
        case .link:
            linkCard
        case .activity:
            activityCard
        case .transfer:
            transferCard
        }
    }

    private var linkCard: some View {
        Button {
            if let url = message?.linkURLString, !url.isEmpty {
                onOpenLink?(url)
            }
        } label: {
            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(message?.linkTitle ?? text).font(.subheadline.weight(.semibold))
                if let subtitle = message?.linkSubtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(PlatformChatBubbleShape.secondaryLabelColor(isMe: isMe))
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(message?.linkURLString?.isEmpty != false)
        .platformChatBubbleStyle(isMe: isMe)
    }

    private var activityCard: some View {
        Button {
            if let id = message?.cardActivityID { onOpenActivity?(id) }
        } label: {
            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Label(MessagesCopy.activityCardLabel, systemImage: "calendar")
                    .font(.caption2.weight(.semibold))
                Text(text).font(.subheadline.weight(.semibold))
                if let subtitle = message?.linkSubtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(PlatformChatBubbleShape.secondaryLabelColor(isMe: isMe))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .platformChatBubbleStyle(isMe: isMe)
    }

    private var transferCard: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
            Label(MessagesCopy.transferTitle, systemImage: "yensign.circle.fill").font(.caption.weight(.semibold))
            Text("¥\(String(format: "%.2f", message?.transferAmount ?? 0))").font(.title3.weight(.semibold))
            if let record = message.flatMap(messagesModel.transferRecord(for:)) {
                Text(MessagesCopy.transferStatusLabel(record.status))
                    .font(.caption.weight(.semibold))
                if record.status == .pending, let remaining = record.pendingTimeRemaining {
                    Text(MessagesCopy.transferExpiresIn(remaining))
                        .font(.caption2)
                        .foregroundStyle(PlatformChatBubbleShape.secondaryLabelColor(isMe: isMe))
                }
                if record.status == .pending {
                    HStack {
                        if isMe {
                            Button(MessagesCopy.transferCancel) {
                                messagesModel.cancelTransfer(record.id)
                            }
                        } else {
                            Button(MessagesCopy.transferAccept) {
                                messagesModel.acceptTransfer(record.id)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else if isMe, record.status == .accepted {
                    Button(MessagesCopy.transferRefund) {
                        messagesModel.refundTransfer(record.id)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            } else {
                Text(MessagesCopy.transferDemoBadge)
                    .font(.caption2)
                    .foregroundStyle(PlatformChatBubbleShape.secondaryLabelColor(isMe: isMe))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .platformChatBubbleStyle(isMe: isMe)
    }

    private var imageBubble: some View {
        Group {
            if let name = message?.mediaLocalName,
               let url = CommunityPhotoStore.fileURL(named: name),
               let ui = UIImage(contentsOfFile: url.path) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: PlatformMessagesChrome.imageBubbleHeight(for: dynamicTypeSize))
                    .clipShape(PlatformChatBubbleShape.unevenRoundedRectangle(isMe: isMe))
                    .platformMessageBubbleMaxWidth(ratio: PlatformMessagesChrome.imageBubbleWidthRatio)
            } else {
                Text(MessagesCopy.imagePlaceholder)
                    .font(.body)
                    .platformChatBubbleStyle(isMe: isMe)
            }
        }
    }

    private var replyQuote: some View {
        VStack(alignment: .leading, spacing: PlatformMessagesChrome.replyCardSpacing) {
            if let replyToSender, !replyToSender.isEmpty {
                Text(replyToSender)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(replyToText ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemFill), in: PlatformMetrics.mediaShape)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1, style: .continuous)
                .fill(Color.accentColor)
                .frame(width: PlatformMetrics.messageReplyAccentWidth)
        }
    }

    @ViewBuilder
    private var leadingAvatarColumn: some View {
        if chrome.showsLeadingAvatar {
            avatarButton
        } else if chrome.reservesLeadingAvatar {
            avatarPlaceholder
        } else if isMe {
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var trailingAvatarColumn: some View {
        if chrome.showsTrailingAvatar {
            avatarButton
        } else if chrome.reservesTrailingAvatar {
            avatarPlaceholder
        } else if !isMe {
            Spacer(minLength: 0)
        }
    }

    private var avatarPlaceholder: some View {
        PlatformSystemAvatar(side: PlatformConversationListRow.imageSide)
            .hidden()
    }

    @ViewBuilder
    private var avatarButton: some View {
        if let onTapAvatar {
            Button(action: onTapAvatar) {
                PlatformSystemAvatar(side: PlatformConversationListRow.imageSide)
            }
            .buttonStyle(.plain)
        } else {
            PlatformSystemAvatar(side: PlatformConversationListRow.imageSide)
        }
    }

    private var noticeBody: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .textSelection(.enabled)
            .padding(9)
            .background(Color(.tertiarySystemFill), in: PlatformMetrics.mediaShape)
            .platformMessageBubbleMaxWidth()
            .frame(maxWidth: .infinity)
    }

    private var accessibilityLabel: String {
        var parts: [String] = []
        if chrome.isNotice { parts.append(MessagesCopy.noticeAccessibility) }
        else if let sender, !isMe { parts.append(sender) }
        if let replyToText { parts.append("回复 \(replyToSender ?? "") \(replyToText)") }
        parts.append(message?.previewText ?? text)
        if liked { parts.append(MessagesCopy.liked) }
        parts.append(Formatters.shortTime.string(from: sentAt))
        return parts.joined(separator: "，")
    }
}

/// 会话输入栏：系统积木拼出「信息」布局。
/// 「+」/ 发送：`.buttonStyle(.glass/.glassProminent)` + `.controlSize(.large)`。
/// 单行胶囊高度 = 同屏实测「+」高度（UIButton large glass 仅首帧回退）；单行不再叠垂直 padding，避免偏高。
/// 间距：`GlassEffectContainer` 与 `HStack` 同用系统 `imageToTextPadding`。
struct PlatformMessageComposerBar<AttachMenu: View>: View {
    @Binding var draft: String
    var placeholder: String
    var isEnabled: Bool
    var canSend: Bool
    var isFocused: FocusState<Bool>.Binding
    var replyPreview: (sender: String, text: String)? = nil
    var onCancelReply: (() -> Void)? = nil
    var onVoice: (() -> Void)? = nil
    var attachMenu: AttachMenu
    var onSend: () -> Void

    @Namespace private var composerGlass
    @State private var toolHeight = PlatformMessagesChrome.composerToolHeightFallback

    private var usesAttachMenu: Bool { AttachMenu.self != EmptyView.self }
    private var showsMicInField: Bool { isEnabled && !canSend && onVoice != nil }
    private var toolSpacing: CGFloat { PlatformMessagesChrome.composerToolSpacing }
    private var locksFieldToToolHeight: Bool {
        !draft.contains(where: \.isNewline)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let replyPreview {
                replyBar(replyPreview)
            }

            GlassEffectContainer(spacing: toolSpacing) {
                HStack(alignment: .center, spacing: toolSpacing) {
                    if isEnabled, usesAttachMenu {
                        Menu {
                            attachMenu
                        } label: {
                            Label(MessagesCopy.attach, systemImage: "plus")
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .controlSize(PlatformMessagesChrome.composerControlSize)
                        .fixedSize()
                        .glassEffectID("composer.plus", in: composerGlass)
                        .background {
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ComposerToolHeightKey.self,
                                    value: proxy.size.height
                                )
                            }
                        }
                    }

                    composerField

                    if canSend {
                        Button(MessagesCopy.send, systemImage: "arrow.up", action: onSend)
                            .labelStyle(.iconOnly)
                            .buttonStyle(.glassProminent)
                            .buttonBorderShape(.circle)
                            .controlSize(PlatformMessagesChrome.composerControlSize)
                            .fixedSize()
                            .disabled(!isEnabled)
                            .glassEffectID("composer.send", in: composerGlass)
                            .background {
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: ComposerToolHeightKey.self,
                                        value: proxy.size.height
                                    )
                                }
                            }
                    }
                }
            }
            .onPreferenceChange(ComposerToolHeightKey.self) { height in
                guard height > 0 else { return }
                toolHeight = height
            }
            .platformMessagePagePadding()
            .padding(
                .top,
                replyPreview == nil
                    ? PlatformMessagesChrome.composerBarVerticalPadding
                    : PlatformMessagesChrome.composerInlineSpacing
            )
            .padding(.bottom, PlatformMessagesChrome.composerBarVerticalPadding)
        }
        .opacity(isEnabled ? 1 : 0.9)
    }

    private var composerField: some View {
        HStack(alignment: .center, spacing: PlatformMessagesChrome.composerInlineSpacing) {
            TextField(
                "",
                text: $draft,
                prompt: Text(placeholder),
                axis: .vertical
            )
            .font(.body)
            .textFieldStyle(.plain)
            .lineLimit(1...5)
            .focused(isFocused)
            .disabled(!isEnabled)
            .submitLabel(.send)
            .onSubmit {
                guard canSend, isEnabled else { return }
                onSend()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showsMicInField {
                Button(MessagesCopy.attachVoice, systemImage: "mic") {
                    onVoice?()
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .controlSize(.small)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, PlatformMessagesChrome.composerFieldHorizontalPadding)
        .padding(
            .vertical,
            locksFieldToToolHeight ? 0 : PlatformMessagesChrome.composerFieldVerticalPadding
        )
        .frame(height: locksFieldToToolHeight ? toolHeight : nil, alignment: .center)
        .glassEffect(.regular.interactive(), in: .capsule)
        .opacity(isEnabled ? 1 : 0.55)
    }

    private func replyBar(_ preview: (sender: String, text: String)) -> some View {
        HStack(alignment: .center, spacing: PlatformMessagesChrome.composerInlineSpacing) {
            VStack(alignment: .leading, spacing: PlatformMessagesChrome.composerInlineSpacing) {
                Text(MessagesCopy.replyingTo(preview.sender))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(preview.text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Button(MessagesCopy.cancelReply, systemImage: "xmark.circle.fill") {
                onCancelReply?()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.secondary)
        }
        .platformMessagePagePadding()
        .padding(.top, PlatformMessagesChrome.composerBarVerticalPadding)
        .padding(.bottom, PlatformMessagesChrome.composerInlineSpacing)
    }
}

private enum ComposerToolHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension PlatformMessageComposerBar where AttachMenu == EmptyView {
    init(
        draft: Binding<String>,
        placeholder: String,
        isEnabled: Bool,
        canSend: Bool,
        isFocused: FocusState<Bool>.Binding,
        replyPreview: (sender: String, text: String)? = nil,
        onCancelReply: (() -> Void)? = nil,
        onSend: @escaping () -> Void
    ) {
        self.init(
            draft: draft,
            placeholder: placeholder,
            isEnabled: isEnabled,
            canSend: canSend,
            isFocused: isFocused,
            replyPreview: replyPreview,
            onCancelReply: onCancelReply,
            onVoice: nil,
            attachMenu: EmptyView(),
            onSend: onSend
        )
    }
}

/// 信息页式未读红点（无数字；系统 danger，非品牌红皮肤）
struct PlatformUnreadDot: View {
    var body: some View {
        PlatformAvatarBadgeDot(fill: PlatformStatus.danger)
            .accessibilityHidden(true)
    }
}

/// 头像角标圆点（在线 / 未读共用尺寸与描边）
struct PlatformAvatarBadgeDot: View {
    var fill: Color

    var body: some View {
        Circle()
            .fill(fill)
            .frame(
                width: PlatformMessagesChrome.presenceDotSize,
                height: PlatformMessagesChrome.presenceDotSize
            )
            .overlay {
                Circle()
                    .stroke(Color(.systemBackground), lineWidth: PlatformMetrics.avatarBadgeStroke)
            }
    }
}

/// 在线状态点（系统 success）
struct PlatformPresenceDot: View {
    var body: some View {
        PlatformAvatarBadgeDot(fill: PlatformStatus.success)
    }
}
