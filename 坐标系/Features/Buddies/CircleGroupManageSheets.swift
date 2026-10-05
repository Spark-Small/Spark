//
//  CircleGroupManageSheets.swift
//  坐标系
//
//  俱乐部群管理附属 Sheet。
//

import SwiftUI
import CoordinateModels

struct CircleMutedNotifySettingsView: View {
    var prefs: OrgMembershipPrefs
    var onPrefsChange: (OrgMembershipPrefs) -> Void

    var body: some View {
        List {
            Section {
                Toggle(CircleGroupCopy.notifyAtMe, isOn: prefBinding(\.notifyWhenMutedAtMe))
                Toggle(CircleGroupCopy.notifyAtAll, isOn: prefBinding(\.notifyWhenMutedAtAll))
                Toggle(CircleGroupCopy.notifyAnnouncement, isOn: prefBinding(\.notifyWhenMutedAnnouncement))
            } footer: {
                Text(CircleGroupCopy.mutedNotifyFooter)
            }
        }
        .navigationTitle(CircleGroupCopy.mutedNotify)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func prefBinding(_ keyPath: WritableKeyPath<OrgMembershipPrefs, Bool>) -> Binding<Bool> {
        Binding(
            get: { prefs[keyPath: keyPath] },
            set: { newValue in
                var next = prefs
                next[keyPath: keyPath] = newValue
                onPrefsChange(next)
            }
        )
    }
}

struct CircleGroupQRSheet: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: PlatformMetrics.sectionSpacing) {
                Spacer(minLength: PlatformMetrics.cardFooterSpacing)
                Image(systemName: "qrcode")
                    .font(.system(size: 160))
                    .foregroundStyle(.primary)
                    .platformSymbolStyle(.hierarchical)
                Text(title)
                    .font(.headline)
                Text(CircleGroupManageCopy.qrHint(title))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding()
            .navigationTitle(CircleGroupCopy.qrCode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CircleGroupManageCopy.close) { dismiss() }
                }
            }
        }
        .platformSheet(.confirm)
    }
}

struct CircleGroupRenameSheet: View {
    let initialTitle: String
    var onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(CircleGroupCopy.chatName, text: $draft)
                        .platformFormTextInput(.singleLine)
                }
            }
            .navigationTitle(CircleGroupManageCopy.renameTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CircleGroupManageCopy.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(CircleGroupManageCopy.save) {
                        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { draft = initialTitle }
        }
        .platformSheet(.form)
    }
}

struct CircleGroupTransferSheet: View {
    let groupName: String
    let candidates: [String]
    var onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if candidates.isEmpty {
                        Text(CircleGroupManageCopy.transferEmpty)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(candidates, id: \.self) { name in
                            Button {
                                onSelect(name)
                                dismiss()
                            } label: {
                                HStack {
                                    PlatformListAvatarView(name: name, side: 36)
                                    Text(name)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } footer: {
                    Text(CircleGroupManageCopy.transferFooter)
                }
            }
            .navigationTitle(CircleGroupCopy.transferOwnership)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CircleGroupManageCopy.cancel) { dismiss() }
                }
            }
        }
        .platformSheet(.form)
    }
}

struct CircleGroupAddAdminSheet: View {
    let candidates: [String]
    var onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if candidates.isEmpty {
                        Text(CircleGroupManageCopy.addAdminEmpty)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(candidates, id: \.self) { name in
                            Button {
                                onSelect(name)
                                dismiss()
                            } label: {
                                HStack {
                                    PlatformListAvatarView(name: name, side: 36)
                                    Text(name)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } footer: {
                    Text(CircleGroupManageCopy.addAdminFooter(max: CircleGroupManageView.maxAdminCount))
                }
            }
            .navigationTitle(CircleGroupCopy.addAdmin)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(CircleGroupManageCopy.cancel) { dismiss() }
                }
            }
        }
        .platformSheet(.form)
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

struct GroupNicknameEditView: View {
    let realName: String
    let initial: String
    var onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: String

    init(realName: String, initial: String, onSave: @escaping (String) -> Void) {
        self.realName = realName
        self.initial = initial
        self.onSave = onSave
        _draft = State(initialValue: initial)
    }

    var body: some View {
        Form {
            Section {
                TextField(CircleGroupManageCopy.groupNicknameField, text: $draft)
                    .platformFormTextInput(.identifier)
            } footer: {
                Text(CircleGroupManageCopy.groupNicknameFooter(realName: realName))
            }
        }
        .navigationTitle(CircleGroupManageCopy.groupNicknameTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(CircleGroupManageCopy.cancel) { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(CircleGroupManageCopy.save) {
                    onSave(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

