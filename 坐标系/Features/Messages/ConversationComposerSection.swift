//
//  ConversationComposerSection.swift
//  坐标系
//
//  会话详情底栏：提及条、冷启动限制、系统 Composer（本机语音入口已接，真录音待 B5）。
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
    let memberNamesExcludingSelf: [String]
    var onCancelReply: () -> Void
    var onSend: () -> Void
    var onVoice: (() -> Void)? = nil
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
                    .padding(.vertical, PlatformMessagesChrome.composerBarVerticalPadding)
                }
            }
            if isOutboundBlocked {
                Text(MessagesCopy.outboundBlockedNotice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .platformMessagePagePadding()
                    .padding(.vertical, PlatformMessagesChrome.composerBarVerticalPadding)
                    .background(PlatformSurface.canvas)
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
}
