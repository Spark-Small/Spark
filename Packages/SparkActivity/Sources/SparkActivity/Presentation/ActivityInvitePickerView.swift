// Module: SparkActivity — Select matched friends to invite in-app.

import SparkDesignSystem
import SwiftUI

struct ActivityInvitePickerView: View {
    let activity: ActivityDetail
    let candidates: [ActivityInviteCandidate]
    let onInvite: ([ActivityInviteCandidate]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedIDs: Set<String> = []
    @State private var didCopy = false

    var body: some View {
        NavigationStack {
            List {
                if candidates.isEmpty {
                    ContentUnavailableView(
                        String(
                            localized: "activity.invitePicker.empty.title",
                            defaultValue: "暂无可邀请好友",
                            comment: "Empty invite picker"
                        ),
                        systemImage: "person.2",
                        description: Text(
                            String(
                                localized: "activity.invitePicker.empty.subtitle",
                                defaultValue: "配对后可在消息页看到好友",
                                comment: "Empty invite picker hint"
                            )
                        )
                    )
                } else {
                    Section {
                        ForEach(candidates) { candidate in
                            Button {
                                toggle(candidate.id)
                            } label: {
                                HStack(spacing: 12) {
                                    inviteAvatar(for: candidate)
                                    Text(candidate.displayName)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedIDs.contains(candidate.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.sparkPressable)
                        }
                    } footer: {
                        Text(
                            String(
                                localized: "activity.invitePicker.footer",
                                defaultValue: "将复制邀请文案，你可粘贴发给选中的好友。",
                                comment: "Invite picker footer"
                            )
                        )
                    }
                }
            }
            .navigationTitle(
                String(localized: "activity.invitePicker.title", defaultValue: "邀请好友", comment: "Invite picker")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(
                        String(localized: "activity.invitePicker.copy", defaultValue: "复制邀请", comment: "Copy invite")
                    ) {
                        copyInvite()
                    }
                    .disabled(selectedIDs.isEmpty)
                }
            }
            .alert(
                String(
                    localized: "activity.invitePicker.copied.title",
                    defaultValue: "已复制邀请文案",
                    comment: "Copied invite"
                ),
                isPresented: $didCopy
            ) {
                Button(String(localized: "common.ok", defaultValue: "好", comment: "OK"), role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(
                    String(
                        format: String(
                            localized: "activity.invitePicker.copied.format",
                            defaultValue: "已复制，可粘贴发给 %lld 位好友",
                            comment: "Copied count; %lld is count"
                        ),
                        locale: .current,
                        selectedIDs.count
                    )
                )
            }
        }
    }

    @ViewBuilder
    private func inviteAvatar(for candidate: ActivityInviteCandidate) -> some View {
        if let url = candidate.avatarURL {
            SparkCachedRemoteImage(
                url: url,
                maxPixelSize: 128,
                content: { image in
                    image.resizable().scaledToFill().accessibilityHidden(true)
                },
                placeholder: {
                    Color(.tertiarySystemFill)
                }
            )
            .frame(width: 40, height: 40)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 40, height: 40)
        }
    }

    private func toggle(_ id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func copyInvite() {
        let selected = candidates.filter { selectedIDs.contains($0.id) }
        ActivityPasteboard.copy(ActivityInviteURL.inviteCopyText(activity: activity))
        onInvite(selected)
        didCopy = true
    }
}

#Preview {
    if let activity = MockActivityCatalog.detail(id: "act_1") {
        ActivityInvitePickerView(
            activity: activity,
            candidates: [
                ActivityInviteCandidate(id: "u1", displayName: "Alex"),
                ActivityInviteCandidate(id: "u2", displayName: "Sam")
            ],
            onInvite: { _ in }
        )
    }
}
