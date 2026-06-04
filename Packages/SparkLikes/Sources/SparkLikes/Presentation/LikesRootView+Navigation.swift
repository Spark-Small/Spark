// Module: SparkLikes — Toolbar, sheets bindings, navigation helpers.

import SwiftUI

extension LikesRootView {
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Text(
                String(localized: "screen.likes", defaultValue: "喜欢", comment: "Likes screen")
            )
            .font(.headline)
            .foregroundStyle(.white)
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                showInbound = true
            } label: {
                Label {
                    Text(
                        String(
                            localized: "likes.inbound.toolbar",
                            defaultValue: "喜欢你的人",
                            comment: "Inbound toolbar"
                        )
                    )
                } icon: {
                    Image(systemName: "heart.text.square")
                }
                .labelStyle(.iconOnly)
                .overlay(alignment: .topTrailing) {
                    if viewModel.inboundCount > 0 {
                        Text("\(viewModel.inboundCount)")
                            .font(.caption2.weight(.bold))
                            .padding(4)
                            .background(.pink, in: Circle())
                            .foregroundStyle(.white)
                            .offset(x: 6, y: -6)
                    }
                }
            }
            .accessibilityLabel(inboundToolbarAccessibilityLabel)

            Menu {
                if viewModel.preferences.intent == .friends {
                    Button {
                        Task { await viewModel.friendRequestCurrentCard() }
                    } label: {
                        Label(
                            String(localized: "likes.friend.a11y", defaultValue: "加好友", comment: "Friend"),
                            systemImage: "person.badge.plus"
                        )
                    }
                    .disabled(viewModel.currentCard == nil || viewModel.isPerformingAction)
                }
                Button {
                    Task { await viewModel.rewindLastPass() }
                } label: {
                    Label(
                        String(localized: "likes.rewind.a11y", defaultValue: "撤回上一位", comment: "Rewind"),
                        systemImage: "arrow.uturn.backward"
                    )
                }
                .disabled(viewModel.isPerformingAction)
                Button {
                    showPreferences = true
                } label: {
                    Label(
                        String(localized: "likes.settings.a11y", defaultValue: "发现偏好", comment: "Settings"),
                        systemImage: "slider.horizontal.3"
                    )
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel(
                String(localized: "likes.more.a11y", defaultValue: "更多", comment: "More menu")
            )
        }
    }

    var matchSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingMatch != nil },
            set: { isPresented in
                if !isPresented, viewModel.pendingMatch != nil {
                    viewModel.dismissMatchWithoutMessage()
                }
            }
        )
    }

    var statusAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.statusMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearStatusMessage()
                }
            }
        )
    }

    var directMessageAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingDirectMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearDirectMessagePresentation()
                }
            }
        )
    }

    func consumePendingInboundIfNeeded() {
        guard pendingInbound else { return }
        showInbound = true
        pendingInbound = false
    }

    func directMessageBody(for peerName: String) -> String {
        let format = String(
            localized: "likes.direct.message.format",
            defaultValue: "你和 %@ 已经可以聊天了",
            comment: "Direct message alert; %@ is name"
        )
        return String(format: format, locale: .current, peerName)
    }

    func openMatchConversation(initialMessage: String?) async {
        guard let match = viewModel.pendingMatch,
              let threadID = match.threadID,
              let name = viewModel.pendingMatchPeerName else {
            viewModel.dismissMatchWithoutMessage()
            return
        }
        viewModel.completeMatchWithMessage(initialMessage)
        await onOpenMatchConversation(threadID, name, initialMessage)
    }

    func openPendingDirectMessage() async {
        guard let pending = viewModel.pendingDirectMessage else { return }
        viewModel.clearDirectMessagePresentation()
        await onOpenMatchConversation(pending.threadID, pending.peerName, nil)
    }

    private var inboundToolbarAccessibilityLabel: String {
        let format = String(
            localized: "likes.inbound.a11y.format",
            defaultValue: "%lld 人喜欢你",
            comment: "Inbound toolbar a11y"
        )
        return String(format: format, locale: .current, viewModel.inboundCount)
    }
}
