//
//  MessagesInboxFilter.swift
//  坐标系
//
//  收件箱筛选 Menu：全部 / 未读 / 群聊；陌生人信箱入口在「全部已读」上方。
//  角标与列表同源：生效筛选 = 当前列表条数；陌生人计数挂在信箱行。
//

import SwiftUI
import CoordinateModels

enum MessagesInboxFilter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all
    case unread
    case groups

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: MessagesCopy.filterAll
        case .unread: MessagesCopy.filterUnread
        case .groups: MessagesCopy.filterGroups
        }
    }

    var systemImage: String {
        switch self {
        case .all: "tray"
        case .unread: "envelope.badge"
        case .groups: "person.3"
        }
    }

    var toolbarSystemImage: String {
        isActive ? systemImage : "line.3.horizontal.decrease"
    }

    var isActive: Bool { self != .all }

    func matches(_ conversation: ChatConversation) -> Bool {
        switch self {
        case .all:
            return true
        case .unread:
            return conversation.unreadCount > 0
        case .groups:
            return conversation.isGroup
        }
    }
}

struct MessagesInboxFilterMenu: View {
    @Binding var filter: MessagesInboxFilter
    var counts: MessagesInboxFilterCounts
    var onOpenStrangerMailbox: (() -> Void)?
    var onMarkAllRead: (() -> Void)?

    private var toolbarBadge: Int { counts.toolbarBadge(for: filter) }
    private var showsMarkAllRead: Bool { onMarkAllRead != nil && counts.unread > 0 }

    var body: some View {
        Menu {
            Picker(selection: $filter) {
                ForEach(MessagesInboxFilter.allCases) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .tag(item)
                        .badge(pickerBadge(for: item))
                }
            } label: {
                Text(MessagesCopy.filterMenuTitle)
            }
            .pickerStyle(.inline)

            if onOpenStrangerMailbox != nil || showsMarkAllRead {
                Divider()
            }

            if let onOpenStrangerMailbox {
                Button(MessagesCopy.strangerMailboxTitle, systemImage: "tray.full") {
                    onOpenStrangerMailbox()
                }
                .badge(counts.strangers)
            }

            if let onMarkAllRead, showsMarkAllRead {
                Button(MessagesCopy.markAllRead, systemImage: "envelope.open", action: onMarkAllRead)
            }
        } label: {
            Label(
                filter.isActive
                    ? MessagesCopy.filterMenuTitleActive
                    : MessagesCopy.filterMenuTitle,
                systemImage: filter.toolbarSystemImage
            )
        }
        .badge(toolbarBadge)
        .platformNavigationBarItemChrome()
        .accessibilityLabel(
            filter.isActive
                ? MessagesCopy.filterMenuTitleActive
                : MessagesCopy.filterMenuTitle
        )
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(MessagesCopy.filterMenuHint)
    }

    /// Picker 行角标：未读 / 群聊显示对应会话条数；「全部」不标，避免与列表长度抢注意力。
    private func pickerBadge(for item: MessagesInboxFilter) -> Int {
        switch item {
        case .all: 0
        case .unread, .groups: counts.conversations(for: item)
        }
    }

    private var accessibilityValue: String {
        if filter.isActive {
            return MessagesCopy.filterMenuValue(filter.title, count: toolbarBadge)
        }
        if counts.strangers > 0 {
            return MessagesCopy.strangerMailboxBadgeA11y(counts.strangers)
        }
        return filter.title
    }
}
