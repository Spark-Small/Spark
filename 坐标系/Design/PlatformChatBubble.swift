//
//  PlatformChatBubble.swift
//  坐标系
//
//  会话气泡主体。
//

import SwiftUI
import CoordinateModels

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
    var onRetrySend: (() -> Void)? = nil

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
                        PlatformMotion.withAnimation(.easeOut(duration: 0.15)) {
                            showsTime.toggle()
                        }
                    }
                if let reaction, !reaction.isEmpty {
                    Text(reaction)
                        .font(.caption)
                        .padding(PlatformMetrics.hairlineSpacing)
                        .platformThinMaterialBackground(in: Capsule())
                }
                if showsTime
                    || (isMe && message?.deliveryStatus == .read)
                    || (isMe && message?.deliveryStatus == .failed) {
                    HStack(spacing: PlatformMetrics.hairlineSpacing) {
                        if showsTime {
                            Text(Formatters.shortTime.string(from: sentAt))
                        }
                        if isMe, let status = message?.deliveryStatus {
                            switch status {
                            case .failed:
                                Button {
                                    onRetrySend?()
                                } label: {
                                    Text("\(MessagesCopy.failedStatus) · \(MessagesCopy.retrySend)")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(PlatformStatus.danger)
                            case .read:
                                Text(MessagesCopy.seenStatus)
                                    .foregroundStyle(.tertiary)
                            case .delivered:
                                Text(MessagesCopy.deliveredStatus)
                                    .foregroundStyle(.tertiary)
                            case .sent:
                                Text(MessagesCopy.sentStatus)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .font(.caption2)
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
               let url = CommunityPhotoStore.fileURL(named: name) {
                PlatformAsyncFileImage(fileURL: url, placeholder: MessagesCopy.imagePlaceholder)
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
        if isMe, let status = message?.deliveryStatus {
            switch status {
            case .failed: parts.append(MessagesCopy.failedStatus)
            case .read: parts.append(MessagesCopy.seenStatus)
            case .delivered: parts.append(MessagesCopy.deliveredStatus)
            case .sent: parts.append(MessagesCopy.sentStatus)
            }
        }
        parts.append(Formatters.shortTime.string(from: sentAt))
        return parts.joined(separator: "，")
    }
}

/// 会话输入栏：系统积木拼出「信息」布局。
/// 「+」/ 发送：`.buttonStyle(.glass/.glassProminent)` + `.controlSize(.large)`。
/// 单行胶囊高度 = 同屏实测「+」高度（`PlatformChromeMeasurements` 公式初值 + Preference 收敛）。
/// 间距：`GlassEffectContainer` 与 `HStack` 同用系统 `imageToTextPadding`。
