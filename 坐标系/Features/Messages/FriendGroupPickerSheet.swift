//
//  FriendGroupPickerSheet.swift
//  坐标系
//
//  好友分组：选择预设 / 自建组；支持新建与滑动删除自建组。
//

import SwiftUI

struct FriendGroupPickerSheet: View {
    let nickname: String

    @Environment(MessagesModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateGroup = false
    @State private var newGroupDraft = ""

    private var currentGroup: String { model.group(for: nickname) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(model.availableFriendGroups, id: \.self) { option in
                        Button {
                            model.setGroup(option, for: nickname)
                            dismiss()
                        } label: {
                            HStack {
                                Text(option)
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 0)
                                if currentGroup == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .accessibilityAddTraits(currentGroup == option ? .isSelected : [])
                        .deleteDisabled(!model.canRemoveFriendGroup(option))
                    }
                    .onDelete(perform: deleteGroups)
                }

                Section {
                    Button {
                        newGroupDraft = ""
                        showCreateGroup = true
                    } label: {
                        Label(MessagesCopy.friendNewGroup, systemImage: "plus")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(MessagesCopy.friendSetGroup)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MessagesCopy.cancel) { dismiss() }
                }
            }
            .alert(MessagesCopy.friendNewGroup, isPresented: $showCreateGroup) {
                TextField(MessagesCopy.friendNewGroupPlaceholder, text: $newGroupDraft)
                    .textInputAutocapitalization(.never)
                Button(MessagesCopy.friendNewGroupCreate) {
                    if model.addFriendGroup(newGroupDraft, assignTo: nickname) {
                        dismiss()
                    }
                }
                Button(MessagesCopy.cancel, role: .cancel) {}
            } message: {
                Text(MessagesCopy.friendNewGroupHint)
            }
        }
        .platformSheet(.form)
    }

    private func deleteGroups(at offsets: IndexSet) {
        let groups = model.availableFriendGroups
        for index in offsets {
            guard groups.indices.contains(index) else { continue }
            model.removeFriendGroup(groups[index])
        }
    }
}
