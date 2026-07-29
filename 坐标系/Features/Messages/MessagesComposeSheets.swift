//
//  MessagesComposeSheets.swift
//  坐标系
//
//  发起聊天：选 1 位好友私聊，选多位创建群聊。
//

import SwiftUI

struct StartChatSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(MessagesModel.self) private var messages
    @Environment(\.dismiss) private var dismiss

    var onOpenConversation: (ChatConversation.ID) -> Void

    @State private var searchText = ""
    @State private var selectedNames: Set<String> = []

    private var friends: [String] {
        MessagesContactRoster.nicknames(
            conversations: messages.conversations,
            inviteNicknames: buddies.inviteRecords.map(\.nickname),
            bookingNicknames: buddies.bookingRecords.map(\.companionNickname),
            blockedNames: Array(app.blockedUserNames)
        )
    }

    private var filteredFriends: [String] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return friends }
        return friends.filter {
            $0.localizedCaseInsensitiveContains(trimmed)
                || messages.displayName(for: $0).localizedCaseInsensitiveContains(trimmed)
                || messages.remark(for: $0).localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var canConfirm: Bool { !selectedNames.isEmpty }

    var body: some View {
        NavigationStack {
            List {
                if friends.isEmpty {
                    ContentUnavailableView(
                        MessagesCopy.startChatEmptyTitle,
                        systemImage: "person.2",
                        description: Text(MessagesCopy.startChatEmptyDescription)
                    )
                    .listRowBackground(Color.clear)
                    .messagesListRow()
                } else if filteredFriends.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .listRowBackground(Color.clear)
                        .messagesListRow()
                } else {
                    ForEach(filteredFriends, id: \.self) { name in
                        Button {
                            toggle(name)
                        } label: {
                            friendRow(name)
                        }
                        .buttonStyle(.plain)
                        .messagesListRow()
                    }
                }
            }
            .platformConversationListChrome()
            .safeAreaInset(edge: .top, spacing: 0) {
                Text(MessagesCopy.startChatFooter)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PlatformMetrics.contentInset)
                    .padding(.vertical, PlatformMetrics.minContentGap)
                    .background(.bar)
            }
            .navigationTitle(MessagesCopy.startChatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: MessagesCopy.startChatSearch
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MessagesCopy.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(MessagesCopy.startChatConfirm) {
                        confirm()
                    }
                    .disabled(!canConfirm)
                    .fontWeight(.semibold)
                }
            }
        }
        .platformSheet(.browser)
    }

    @ViewBuilder
    private func friendRow(_ name: String) -> some View {
        let isSelected = selectedNames.contains(name)
        HStack(spacing: PlatformMetrics.railCardSpacing) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .imageScale(.large)

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(messages.displayName(for: name))
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if messages.displayName(for: name) != name {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: PlatformMetrics.hairlineSpacing)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(messages.displayName(for: name))
    }

    private func toggle(_ name: String) {
        if selectedNames.contains(name) {
            selectedNames.remove(name)
        } else {
            selectedNames.insert(name)
        }
    }

    private func confirm() {
        let ordered = friends.filter { selectedNames.contains($0) }
        guard let conversation = messages.startChat(
            withMembers: ordered,
            ownerName: app.user.name
        ) else { return }
        dismiss()
        onOpenConversation(conversation.id)
    }
}

/// 通讯录 / 发起聊天共用的好友昵称来源
enum MessagesContactRoster {
    static func nicknames(
        conversations: [ChatConversation],
        inviteNicknames: [String],
        bookingNicknames: [String],
        blockedNames: [String]
    ) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        func append(_ name: String) {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.lowercased()
            guard !key.isEmpty, !seen.contains(key) else { return }
            if blockedNames.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                return
            }
            seen.insert(key)
            result.append(trimmed)
        }

        for conversation in conversations where conversation.isFriendChat && !conversation.isMessageRequest {
            append(conversation.title)
        }
        for name in inviteNicknames { append(name) }
        for name in bookingNicknames { append(name) }

        return result.sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }
}

/// 兼容旧调用名
typealias StartGroupChatSheet = StartChatSheet
