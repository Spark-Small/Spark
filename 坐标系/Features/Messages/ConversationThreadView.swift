//
//  ConversationThreadView.swift
//  坐标系
//
//  会话详情消息时间轴：加载更早、滚动锚点、空态。
//

import SwiftUI
import CoordinateModels

struct ConversationThreadView<Row: View>: View {
    let peerName: String
    let timeline: [ChatTimelineItem]
    let isEmpty: Bool
    let canLoadOlder: Bool
    let messageCount: Int
    let messageIDs: [ChatMessage.ID]
    var focusMessageID: ChatMessage.ID?
    @Binding var pendingScrollMessageID: ChatMessage.ID?
    var onLoadOlder: () -> Void
    var onAppearThread: () -> Void
    var onDisappearThread: () -> Void
    var onMessageIDsChanged: ([ChatMessage.ID]) -> Void
    @ViewBuilder var row: (ChatMessage, PlatformChatBubbleChrome) -> Row

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if canLoadOlder {
                        Button(MessagesCopy.loadOlderMessages, action: onLoadOlder)
                            .font(.footnote.weight(.semibold))
                            .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
                    }
                    if isEmpty {
                        PlatformChatEmptyThread(peerName: peerName)
                    } else {
                        ForEach(timeline) { item in
                            switch item {
                            case .day(let label, let id):
                                PlatformChatDaySeparator(label: label)
                                    .id(id)
                            case .tip(let message):
                                PlatformChatSystemTip(text: message.text)
                                    .id(message.id)
                            case .message(let message, let chrome):
                                row(message, chrome)
                                    .id(message.id)
                            }
                        }
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .platformMessageThreadScrollMargins()
            .onChange(of: messageCount) { _, _ in
                if pendingScrollMessageID == nil {
                    scrollToLatest(using: proxy)
                }
            }
            .onAppear {
                onAppearThread()
                if let focusMessageID,
                   messageIDs.contains(focusMessageID) {
                    DispatchQueue.main.async {
                        PlatformMotion.withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(focusMessageID, anchor: .center)
                        }
                        pendingScrollMessageID = nil
                    }
                } else {
                    scrollToLatest(using: proxy, animated: false)
                    pendingScrollMessageID = nil
                }
            }
            .onDisappear(perform: onDisappearThread)
            .onChange(of: messageIDs) { _, ids in
                onMessageIDsChanged(ids)
            }
        }
    }

    private func scrollToLatest(using proxy: ScrollViewProxy, animated: Bool = true) {
        guard let id = messageIDs.last else { return }
        if animated {
            PlatformMotion.withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(id, anchor: .bottom)
        }
    }
}
