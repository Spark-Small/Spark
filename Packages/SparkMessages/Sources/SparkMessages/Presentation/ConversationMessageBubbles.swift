// Module: SparkMessages — Conversation message bubble views.

import SparkDesignSystem
import SwiftUI

struct ConversationMessageView: View {
    let message: ChatMessage
    var onOpenActivity: ((String) -> Void)?

    var body: some View {
        switch message.kind {
        case .text:
            ChatBubble(message: message)
        case .system:
            SystemMessageBubble(message: message, onOpenActivity: onOpenActivity)
        case .activityShare:
            ActivityShareBubble(message: message, onOpenActivity: onOpenActivity)
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isFromCurrentUser { Spacer(minLength: 48) }
            Text(message.body)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    Color.clear
                        .sparkGlassSurface(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            if !message.isFromCurrentUser { Spacer(minLength: 48) }
        }
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let role = message.isFromCurrentUser
            ? String(localized: "messages.bubble.you", defaultValue: "你", comment: "You sent")
            : String(localized: "messages.bubble.them", defaultValue: "对方", comment: "Peer sent")
        return "\(role): \(message.body)"
    }
}

struct SystemMessageBubble: View {
    let message: ChatMessage
    let onOpenActivity: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 8) {
            if let payload = message.systemPayload {
                VStack(alignment: .leading, spacing: 8) {
                    Text(payload.typeLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(payload.title)
                        .font(.headline)
                    Text(payload.body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let ctaTitle = payload.ctaTitle, let activityID = payload.ctaActivityID {
                        Button(ctaTitle) {
                            onOpenActivity?(activityID)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityHint(
                            String(
                                localized: "messages.system.cta.hint",
                                defaultValue: "打开活动详情",
                                comment: "Open activity hint"
                            )
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .sparkGlassSurface(RoundedRectangle.sparkCard)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActivityShareBubble: View {
    let message: ChatMessage
    let onOpenActivity: ((String) -> Void)?

    var body: some View {
        Button {
            if let activityID = message.activityID {
                onOpenActivity?(activityID)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "figure.hiking")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        String(localized: "messages.activity.share", defaultValue: "分享的活动", comment: "Shared activity")
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Text(
                        String(localized: "messages.activity.viewDetail", defaultValue: "查看详情", comment: "View detail")
                    )
                    .font(.subheadline.weight(.semibold))
                }
                Spacer()
            }
            .padding(14)
            .sparkGlassSurface(RoundedRectangle.sparkCard)
        }
        .buttonStyle(.sparkPressable)
        .frame(maxWidth: .infinity, alignment: message.isFromCurrentUser ? .trailing : .leading)
        .accessibilityLabel(
            String(localized: "messages.activity.share", defaultValue: "分享的活动", comment: "Shared activity")
        )
    }
}

#Preview("Message bubbles") {
    let threadID = MessageThreadID("preview_thread")
    VStack(spacing: 16) {
        ChatBubble(
            message: ChatMessage(
                id: "m1",
                threadID: threadID,
                body: "周末有空一起喝咖啡吗？",
                sentAt: .now,
                isFromCurrentUser: false
            )
        )
        ChatBubble(
            message: ChatMessage(
                id: "m2",
                threadID: threadID,
                body: "好啊，周六下午？",
                sentAt: .now,
                isFromCurrentUser: true
            )
        )
    }
    .padding()
}

#Preview("Message bubbles") {
    let threadID = MessageThreadID("preview_thread")
    VStack(spacing: 16) {
        ChatBubble(
            message: ChatMessage(
                id: "m1",
                threadID: threadID,
                body: "周末有空一起喝咖啡吗？",
                sentAt: .now,
                isFromCurrentUser: false
            )
        )
        ChatBubble(
            message: ChatMessage(
                id: "m2",
                threadID: threadID,
                body: "好啊，周六下午？",
                sentAt: .now,
                isFromCurrentUser: true
            )
        )
    }
    .padding()
}
