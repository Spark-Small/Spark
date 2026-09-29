//
//  ConversationComposerSection.swift
//  坐标系
//
//  会话详情底栏：提及条、冷启动限制、快捷回复、系统 Composer。
//

import PhotosUI
import SwiftUI
import CoordinateModels

struct ConversationComposerSection<AttachMenu: View>: View {
    let conversation: ChatConversation
    @Binding var draft: String
    var isComposerFocused: FocusState<Bool>.Binding
    @Binding var mentionDraft: String?
    let replyTo: ChatMessage?
    let isOutboundBlocked: Bool
    let composerEnabled: Bool
    let canSend: Bool
    let quickReplySectionTitle: String
    let quickReplyTemplates: [(label: String, text: String)]
    let memberNamesExcludingSelf: [String]
    var onCancelReply: () -> Void
    var onVoice: () -> Void
    var onSend: () -> Void
    var onQuickReply: (String) -> Void
    @ViewBuilder var attachMenu: () -> AttachMenu

    var body: some View {
        VStack(spacing: 0) {
            if mentionDraft != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                        ForEach(memberNamesExcludingSelf, id: \.self) { name in
                            Button("@\(name)") {
                                draft += "@\(name) "
                                mentionDraft = nil
                                isComposerFocused.wrappedValue = true
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .platformMessagePagePadding()
                    .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
                }
            }
            if isOutboundBlocked {
                Text(MessagesCopy.outboundBlockedNotice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .platformMessagePagePadding()
                    .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
                    .background(PlatformSurface.canvas)
            } else if !quickReplyTemplates.isEmpty {
                quickReplyBar
            }
            PlatformMessageComposerBar(
                draft: $draft,
                placeholder: conversation.kind == .notice
                    ? MessagesCopy.noticePlaceholder
                    : MessagesCopy.sendPlaceholder,
                isEnabled: composerEnabled,
                canSend: canSend,
                isFocused: isComposerFocused,
                replyPreview: replyTo.map {
                    ($0.isMe ? "我" : $0.sender, $0.previewText)
                },
                onCancelReply: onCancelReply,
                onVoice: onVoice,
                attachMenu: attachMenu(),
                onSend: onSend
            )
        }
    }

    private var quickReplyBar: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.formRowVerticalPadding) {
            Text(quickReplySectionTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .platformMessagePagePadding()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                    ForEach(quickReplyTemplates, id: \.label) { template in
                        Button(template.label) {
                            onQuickReply(template.text)
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .accessibilityLabel("\(MessagesCopy.quickReplySectionTitle)：\(template.text)")
                    }
                }
                .platformMessagePagePadding()
            }
        }
        .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
        .background(PlatformSurface.canvas)
    }
}
