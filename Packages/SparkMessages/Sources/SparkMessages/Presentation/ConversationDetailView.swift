// Module: SparkMessages — Thread detail with rich message kinds.

import SparkDesignSystem
import SwiftUI

public struct ConversationDetailView: View {
    @Bindable public var viewModel: ConversationViewModel
    public var onOpenActivity: ((String) -> Void)?

    public init(viewModel: ConversationViewModel, onOpenActivity: ((String) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onOpenActivity = onOpenActivity
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
        .safeAreaInset(edge: .top) {
            if viewModel.isGroupChat {
                groupActivityBanner
            } else if viewModel.isDirectMessage {
                dmContextHeader
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if let sendError = viewModel.sendErrorMessage {
                    Text(sendError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .accessibilityLabel(sendError)
                }
                composerBar
            }
        }
        .task {
            if viewModel.loadState == .idle {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var groupActivityBanner: some View {
        if let activity = viewModel.groupBannerActivity {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline.weight(.semibold))
                Text(activity.countdownText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial)
        }
    }

    @ViewBuilder
    private var dmContextHeader: some View {
        if let activities = viewModel.context?.sharedActivities, !activities.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(activities) { activity in
                        Button {
                            onOpenActivity?(activity.id)
                        } label: {
                            dmSharedActivityChip(activity: activity)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(.thinMaterial)
        }
    }

    private func dmSharedActivityChip(activity: InboxActivitySummary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(
                String(localized: "messages.dm.sharedActivity", defaultValue: "共同活动", comment: "Shared activity")
            )
            .font(.caption2)
            .foregroundStyle(.secondary)
            Text(activity.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ConversationMessageView(message: message, onOpenActivity: onOpenActivity)
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

#Preview("Conversation — load failure") {
    NavigationStack {
        ConversationDetailView(
            viewModel: ConversationViewModel(
                repository: PreviewFailingConversationRepository(),
                thread: MessageThread(
                    threadID: MessageThreadID("th_dm_u_like_1"),
                    peerDisplayName: "Preview",
                    lastMessagePreview: "",
                    lastActivityAt: .now,
                    unreadCount: 0
                )
            )
        )
    }
}

private struct PreviewFailingConversationRepository: MessagesRepository, Sendable {
    struct Failure: LocalizedError {
        var errorDescription: String? { "Preview failure" }
    }

    func fetchUnreadCount() async throws -> Int { 0 }
    func fetchThreads() async throws -> [MessageThread] { [] }
    func fetchInbox() async throws -> MessagesInbox { MessagesInbox() }
    func fetchMessages(threadID: MessageThreadID) async throws -> [ChatMessage] { throw Failure() }
    func fetchConversationContext(threadID: MessageThreadID) async throws -> ConversationContext { throw Failure() }
    func sendMessage(threadID: MessageThreadID, body: String) async throws -> ChatMessage { throw Failure() }
    func markAllRead() async throws {}
    func respondToActivityInvite(activityID: String, invitationID: String, accept: Bool) async throws {}
    func dismissInboxActionItem(id: String) async throws {}
    func ensureActivityGroupThread(threadID: MessageThreadID, displayName: String, welcomeMessage: String) async throws {}
    func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID {
        MessageThreadID("th_dm_preview")
    }
}
