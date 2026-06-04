// Module: SparkMessages — Thread detail with send composer.

import SparkDesignSystem
import SwiftUI

public struct ConversationDetailView: View {
    @Bindable public var viewModel: ConversationViewModel

    public init(viewModel: ConversationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure(let message):
                SparkRetryUnavailableView(
                    title: String(
                        localized: "messages.conversation.error.title",
                        defaultValue: "无法加载",
                        comment: "Conversation error"
                    ),
                    description: message
                ) {
                    Task { await viewModel.load() }
                }
            case .loaded:
                messageList
            }
        }
        .background(.regularMaterial)
        .navigationTitle(viewModel.thread.peerDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            composerBar
        }
        .task {
            if viewModel.loadState == .idle {
                await viewModel.load()
            }
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var composerBar: some View {
        HStack(spacing: 12) {
            TextField(
                String(localized: "messages.composer.placeholder", defaultValue: "输入消息…", comment: "Composer"),
                text: $viewModel.draftText,
                axis: .vertical
            )
            .lineLimit(1 ... 4)
            .textFieldStyle(.plain)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))

            Button {
                Task { await viewModel.sendTapped() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
            }
            .disabled(viewModel.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            .accessibilityLabel(
                String(localized: "messages.composer.send", defaultValue: "发送", comment: "Send message")
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Bubble

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isFromCurrentUser { Spacer(minLength: 48) }
            Text(message.body)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    bubbleBackground
                }
            if !message.isFromCurrentUser { Spacer(minLength: 48) }
        }
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(message.isFromCurrentUser ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.thinMaterial))
    }

    private var accessibilityText: String {
        let role = message.isFromCurrentUser
            ? String(localized: "messages.bubble.you", defaultValue: "你", comment: "You sent")
            : String(localized: "messages.bubble.them", defaultValue: "对方", comment: "Peer sent")
        return "\(role): \(message.body)"
    }
}

#Preview {
    NavigationStack {
        ConversationDetailView(
            viewModel: ConversationViewModel(
                repository: MockMessagesRepository(unreadCount: 2),
                thread: MessageThread(
                    threadID: MessageThreadID("th_activity_act_1"),
                    peerDisplayName: "周末徒步 · 群",
                    lastMessagePreview: "周六 9:30 北门集合",
                    lastActivityAt: .now,
                    unreadCount: 1
                )
            )
        )
    }
}
