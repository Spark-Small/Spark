//
//  GroupInviteFriendsSheet.swift
//  坐标系
//
//  群详情「邀请」：从本机好友通讯录选人进群。
//

import SwiftUI
import CoordinateModels

struct GroupInviteFriendsSheet: View {
    let conversationID: ChatConversation.ID

    @Environment(MessagesModel.self) private var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selected: Set<String> = []

    private var existingKeys: Set<String> {
        Set(model.groupMembers(for: conversationID).map { $0.nickname.lowercased() })
    }

    private var candidates: [String] {
        MessagesContactRoster.nicknames(
            conversations: model.conversations,
            inviteNicknames: buddies.inviteRecords.map(\.nickname),
            bookingNicknames: buddies.bookingRecords.map(\.companionNickname),
            blockedNames: Array(app.blockedUserNames)
        )
        .filter { !existingKeys.contains($0.lowercased()) }
        .filter {
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return true }
            return $0.localizedCaseInsensitiveContains(trimmed)
                || model.displayName(for: $0).localizedCaseInsensitiveContains(trimmed)
        }
        .sorted {
            model.displayName(for: $0).localizedStandardCompare(model.displayName(for: $1))
                == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if candidates.isEmpty {
                    ContentUnavailableView(
                        MessagesCopy.groupInviteEmptyTitle,
                        systemImage: "person.badge.plus",
                        description: Text(MessagesCopy.groupInviteEmptyDescription)
                    )
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(candidates, id: \.self) { name in
                            Button {
                                toggle(name)
                            } label: {
                                HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                                    PlatformListAvatarView(name: name)
                                    Text(model.displayName(for: name))
                                        .foregroundStyle(.primary)
                                    Spacer(minLength: 0)
                                    if selected.contains(name.lowercased()) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text(MessagesCopy.groupMemberPickerTitle)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(MessagesCopy.groupInviteMembers)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: MessagesCopy.friendsListSearch)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MessagesCopy.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(MessagesCopy.groupInvite) {
                        let names = candidates.filter { selected.contains($0.lowercased()) }
                        model.inviteMembers(names, to: conversationID)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selected.isEmpty)
                }
            }
        }
        .platformSheet(.form)
    }

    private func toggle(_ name: String) {
        let key = name.lowercased()
        if selected.contains(key) {
            selected.remove(key)
        } else {
            selected.insert(key)
        }
    }
}
