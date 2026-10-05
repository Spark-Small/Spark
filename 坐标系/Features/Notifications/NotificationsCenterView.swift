//
//  NotificationsCenterView.swift
//  坐标系
//
//  站内通知中心：PlatformFilterChip + 会话列表行语义（未读 / 滑动操作 / 深链）。
//

import SwiftUI
import CoordinateModels

struct NotificationsCenterView: View {
    @Environment(InAppNotificationStore.self) private var inbox
    @Environment(AppModel.self) private var app

    @State private var categoryFilter: InAppNotificationCategory?
    @State private var showClearConfirm = false

    private var visibleItems: [InAppNotificationItem] {
        inbox.items(in: categoryFilter)
    }

    private var todayItems: [InAppNotificationItem] {
        visibleItems.filter { Calendar.current.isDateInToday($0.createdAt) }
    }

    private var earlierItems: [InAppNotificationItem] {
        visibleItems.filter { !Calendar.current.isDateInToday($0.createdAt) }
    }

    var body: some View {
        List {
            Section {
                filterBar
                    .listRowInsets(PlatformFormControlListRow.insets)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if !visibleItems.isEmpty {
                if !todayItems.isEmpty {
                    Section {
                        ForEach(todayItems) { item in
                            notificationRow(item)
                        }
                    } header: {
                        Text(NotificationsCopy.sectionToday)
                    }
                }
                if !earlierItems.isEmpty {
                    Section {
                        ForEach(earlierItems) { item in
                            notificationRow(item)
                        }
                    } header: {
                        Text(NotificationsCopy.sectionEarlier)
                    }
                }
            }
        }
        .profileSecondaryListChrome()
        .overlay {
            if visibleItems.isEmpty {
                ContentUnavailableView {
                    Label(NotificationsCopy.emptyTitle, systemImage: "bell.slash")
                } description: {
                    Text(NotificationsCopy.emptyDescription)
                } actions: {
                    NavigationLink {
                        SettingsNotificationsView()
                    } label: {
                        Text(NotificationsCopy.settings)
                    }
                }
            }
        }
        .navigationTitle(NotificationsCopy.centerTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { centerToolbar }
        .task {
            await inbox.syncDeliveredFromSystem()
        }
        .confirmationDialog(
            NotificationsCopy.clearAllConfirmTitle,
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button(NotificationsCopy.clearAll, role: .destructive) {
                inbox.removeAll()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(NotificationsCopy.clearAllConfirmMessage)
        }
    }

    private var filterBar: some View {
        PlatformFilterChipBar(padsHorizontally: false) {
            PlatformFilterChipButton(
                title: NotificationsCopy.filterAll,
                systemImage: "bell",
                isSelected: categoryFilter == nil
            ) {
                categoryFilter = nil
            }
            ForEach(InAppNotificationCategory.allCases.filter { $0 != .system }, id: \.self) { category in
                PlatformFilterChipButton(
                    title: category.title,
                    systemImage: category.systemImage,
                    isSelected: categoryFilter == category
                ) {
                    categoryFilter = category
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var centerToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if !inbox.items.isEmpty {
                Menu {
                    if inbox.hasUnread {
                        Button(NotificationsCopy.markAllRead, systemImage: "envelope.open") {
                            inbox.markAllRead()
                        }
                    }
                    Button(NotificationsCopy.clearAll, systemImage: "trash", role: .destructive) {
                        showClearConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .platformNavigationBarItemChrome()
                .accessibilityLabel(NotificationsCopy.moreActions)
            }

            NavigationLink {
                SettingsNotificationsView()
            } label: {
                Image(systemName: "gearshape")
            }
            .platformNavigationBarItemChrome()
            .accessibilityLabel(NotificationsCopy.settings)
            .accessibilityHint(NotificationsCopy.openSettingsHint)
        }
    }

    @ViewBuilder
    private func notificationRow(_ item: InAppNotificationItem) -> some View {
        Button {
            open(item)
        } label: {
            NotificationInboxRow(item: item)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                inbox.remove(item.id)
            } label: {
                Label(NotificationsCopy.swipeDelete, systemImage: "trash")
            }
            if !item.isRead {
                Button {
                    inbox.markRead(item.id)
                } label: {
                    Label(NotificationsCopy.swipeMarkRead, systemImage: "envelope.open")
                }
                .tint(.accentColor)
            }
        }
        .contextMenu {
            if !item.isRead {
                Button(NotificationsCopy.swipeMarkRead, systemImage: "envelope.open") {
                    inbox.markRead(item.id)
                }
            }
            Button(NotificationsCopy.swipeDelete, systemImage: "trash", role: .destructive) {
                inbox.remove(item.id)
            }
        }
    }

    private func open(_ item: InAppNotificationItem) {
        inbox.markRead(item.id)
        if let link = item.deepLink {
            app.handleNotificationDeepLink(link)
        }
    }
}

private struct NotificationInboxRow: View {
    let item: InAppNotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
            ZStack(alignment: .topTrailing) {
                PlatformListSymbolAvatar(
                    systemName: item.category.systemImage,
                    side: PlatformConversationListRow.imageSide
                )
                if !item.isRead {
                    PlatformUnreadDot()
                        .offset(
                            x: PlatformMetrics.avatarBadgeOffset,
                            y: -PlatformMetrics.avatarBadgeOffset
                        )
                }
            }
            .accessibilityHidden(true)

            PlatformListTextColumn(
                primary: item.title,
                secondary: item.body.isEmpty ? item.category.title : item.body,
                footnote: [
                    item.category.title,
                    Formatters.conversationListTime(from: item.createdAt)
                ].joined(separator: " · "),
                primaryLineLimit: 1,
                secondaryLineLimit: 2,
                footnoteLineLimit: 1
            )
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [item.title]
        if !item.body.isEmpty { parts.append(item.body) }
        parts.append(item.category.title)
        if !item.isRead { parts.append(NotificationsCopy.unreadA11y) }
        return parts.joined(separator: "，")
    }
}

#Preview {
    NavigationStack {
        NotificationsCenterView()
            .environment(InAppNotificationStore())
            .environment(AppModel(dependencies: .preview()))
    }
}
