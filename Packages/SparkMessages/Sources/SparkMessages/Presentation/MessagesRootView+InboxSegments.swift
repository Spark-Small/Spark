// Module: SparkMessages — Segmented inbox: 消息 / 群聊.

import SparkDesignSystem
import SwiftUI

extension MessagesRootView {
    var inboxSegmentToolbarPicker: some View {
        Picker("", selection: $selectedInboxSegment) {
            ForEach(MessagesInboxSegment.allCases) { segment in
                Text(segment.localizedTitle).tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: SparkLayoutMetrics.segmentedControlMaxWidth)
        .accessibilityLabel(
            String(
                localized: "messages.inbox.segment.a11y",
                defaultValue: "消息分类",
                comment: "Messages inbox segment picker"
            )
        )
    }

    @ViewBuilder
    var loadedInboxSegmentContent: some View {
        // REASONING: TabView paging isolates scroll views from NavigationStack scroll-edge chrome.
        inboxSegmentInstantContent
    }

    @ViewBuilder
    private var inboxSegmentInstantContent: some View {
        switch selectedInboxSegment {
        case .dm:
            dmInboxSegmentPage
        case .groupChats:
            groupChatsInboxSegmentPage
        }
    }

    private var dmInboxSegmentPage: some View {
        inboxSegmentPage(
            conversations: viewModel.dmConversations,
            emptyContent: dmSegmentEmptyView,
            segment: .dm
        )
    }

    private var groupChatsInboxSegmentPage: some View {
        groupChatsSegmentPage
    }

    @ViewBuilder
    private var groupChatsSegmentPage: some View {
        let active = viewModel.activeGroupChats
        let archived = viewModel.archivedGroupChats
        let filteredActive = MessagesInboxSearchFiltering.filter(active, query: inboxSearchText)
        let filteredArchived = MessagesInboxSearchFiltering.filter(archived, query: inboxSearchText)
        let hasSearch = !inboxSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        inboxConversationList(segment: .groupChats) {
            if active.isEmpty, archived.isEmpty {
                groupSegmentEmptyView
                    .sparkFlatTabListRow()
            } else if hasSearch, filteredActive.isEmpty, filteredArchived.isEmpty {
                inboxSearchEmptyView(segment: .groupChats, archivedHasMatches: false)
                    .sparkFlatTabListRow()
            } else {
                ForEach(filteredActive) { conversation in
                    inboxConversationRow(conversation)
                }
                if !filteredArchived.isEmpty {
                    ArchivedChatsDisclosure(chats: filteredArchived) { chat in
                        archivedGroupChatRow(chat)
                    }
                    .sparkFlatTabListRow()
                }
            }
        }
    }

    @ViewBuilder
    private func inboxSegmentPage<Empty: View>(
        conversations: [ConversationPreview],
        emptyContent: Empty,
        segment: MessagesInboxSegment
    ) -> some View {
        let filtered = MessagesInboxSearchFiltering.filter(conversations, query: inboxSearchText)
        inboxConversationList(segment: segment) {
            if conversations.isEmpty {
                emptyContent
                    .sparkFlatTabListRow()
            } else if filtered.isEmpty {
                inboxSearchEmptyView(segment: segment, archivedHasMatches: false)
                    .sparkFlatTabListRow()
            } else {
                ForEach(filtered) { conversation in
                    inboxConversationRow(conversation)
                }
            }
        }
    }

    private func inboxSearchEmptyView(segment: MessagesInboxSegment, archivedHasMatches: Bool) -> some View {
        ContentUnavailableView {
            Label(
                String(
                    localized: "messages.inbox.search.empty.title",
                    defaultValue: "未找到相关会话",
                    comment: "Inbox search no results"
                ),
                systemImage: "magnifyingglass"
            )
        } description: {
            Text(inboxSearchEmptySubtitle(segment: segment, archivedHasMatches: archivedHasMatches))
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .sparkContentUnavailableCanvas()
    }

    private func inboxSearchEmptySubtitle(segment: MessagesInboxSegment, archivedHasMatches: Bool) -> String {
        if archivedHasMatches {
            return String(
                localized: "messages.inbox.search.empty.archivedHint",
                defaultValue: "试试在「已结束的活动」中查看，或换其他关键词",
                comment: "Search hint when results may be archived"
            )
        }
        switch segment {
        case .dm:
            return String(
                localized: "messages.inbox.search.empty.subtitle.dm",
                defaultValue: "仅在「消息」中搜索，试试联系人名称或聊天预览",
                comment: "DM search no results hint"
            )
        case .groupChats:
            return String(
                localized: "messages.inbox.search.empty.subtitle.groups",
                defaultValue: "仅在「群聊」中搜索，可搜活动名称或群聊预览",
                comment: "Group search no results hint"
            )
        }
    }

    private var dmSegmentEmptyView: some View {
        ContentUnavailableView {
            Label(
                String(
                    localized: "messages.segment.dm.empty.title",
                    defaultValue: "暂无消息",
                    comment: "Empty DM segment"
                ),
                systemImage: "bubble.left.and.bubble.right"
            )
        } description: {
            Text(
                String(
                    localized: "messages.segment.dm.empty.subtitle",
                    defaultValue: "配对成功后可以在这里聊天",
                    comment: "Empty DM segment hint"
                )
            )
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .sparkContentUnavailableCanvas()
    }

    private var groupSegmentEmptyView: some View {
        ContentUnavailableView {
            Label(
                String(
                    localized: "messages.segment.groups.empty.title",
                    defaultValue: "暂无群聊",
                    comment: "Empty group segment"
                ),
                systemImage: "bubble.left.and.bubble.right"
            )
        } description: {
            Text(
                String(
                    localized: "messages.segment.groups.empty.subtitle",
                    defaultValue: "报名活动后会自动加入群聊",
                    comment: "Empty group segment hint"
                )
            )
        } actions: {
            if let onOpenActivityTab {
                Button(
                    String(
                        localized: "messages.segment.groups.empty.cta.activity",
                        defaultValue: "去看看活动",
                        comment: "Open activity tab from empty group segment"
                    ),
                    action: onOpenActivityTab
                )
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .sparkContentUnavailableCanvas()
    }

    func applyInitialInboxSegmentIfNeeded() {
        guard viewModel.loadState == .loaded || viewModel.loadState == .empty,
              !hasAppliedInitialInboxSegment else { return }
        if !viewModel.dmConversations.isEmpty {
            selectedInboxSegment = .dm
        } else if !viewModel.activeGroupChats.isEmpty {
            selectedInboxSegment = .groupChats
        } else {
            selectedInboxSegment = .dm
        }
        hasAppliedInitialInboxSegment = true
    }
}
