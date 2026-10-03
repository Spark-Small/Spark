//
//  GroupManageSheet+Sections.swift
//  坐标系
//
//  群详情分区：概览 / 偏好 / 身份 / 危险操作（对照俱乐部已加入态）。
//

import SwiftUI
import CoordinateModels

extension GroupManageSheet {
    @ViewBuilder
    var overviewSection: some View {
        Section {
            if canRenameChat {
                Button {
                    showRenameSheet = true
                } label: {
                    LabeledContent(CircleGroupCopy.chatName, value: conversation?.title ?? "")
                }
                .buttonStyle(.plain)
            } else {
                LabeledContent(CircleGroupCopy.chatName, value: conversation?.title ?? "")
            }

            Button {
                showQRSheet = true
            } label: {
                HStack {
                    Text(CircleGroupCopy.qrCode)
                    Spacer()
                    Image(systemName: "qrcode")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(CircleGroupCopy.announcement)
                Text(announcementText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
            .padding(.vertical, PlatformMetrics.hairlineSpacing)

            if let activity = relatedActivity {
                Button {
                    onOpenActivity(activity)
                    dismiss()
                } label: {
                    Label(activity.title, systemImage: "calendar")
                }
            }

            NavigationLink {
                CircleGroupManageView(
                    conversationID: conversationID,
                    displayName: conversation?.title ?? MessagesCopy.groupSubtitle,
                    prefs: prefs,
                    onPrefsChange: applyPrefs,
                    onDissolve: {
                        model.dissolveGroup(conversationID: conversationID)
                        dismiss()
                    }
                )
            } label: {
                Text(CircleGroupCopy.manage)
            }
        }
    }

    @ViewBuilder
    var chatPrefsSection: some View {
        Section {
            Button {
                feedback = CircleGroupCopy.searchUnavailable
            } label: {
                Text(CircleGroupCopy.searchChat)
            }

            Toggle(CircleGroupCopy.muteNotifications, isOn: muteBinding)

            if prefs.muteNotifications {
                NavigationLink {
                    CircleMutedNotifySettingsView(
                        prefs: prefs,
                        onPrefsChange: applyPrefs
                    )
                } label: {
                    Text(CircleGroupCopy.mutedNotify)
                }
            }

            Toggle(CircleGroupCopy.pinChat, isOn: pinBinding)
        }
    }

    @ViewBuilder
    var identitySection: some View {
        Section {
            NavigationLink {
                GroupNicknameEditView(
                    realName: app.user.name,
                    initial: myGroupNicknameLabel
                ) { saved in
                    var next = prefs
                    next.myGroupNickname = saved
                    applyPrefs(next)
                    model.setGroupAlias(saved, forMember: app.user.name, in: conversationID)
                }
            } label: {
                LabeledContent(CircleGroupManageCopy.groupNicknameTitle, value: myGroupNicknameLabel)
            }

            Toggle(CircleGroupCopy.showMemberNicknames, isOn: nicknamesBinding)
        }
    }

    @ViewBuilder
    var destructiveSection: some View {
        Section {
            Button(CircleGroupCopy.clearHistory, role: .destructive) {
                confirmClearHistory = true
            }

            Button(leaveActionTitle, role: .destructive) {
                confirmLeave = true
            }
        }
    }

    private var announcementText: String {
        let raw = conversation?.announcement?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return raw.isEmpty ? MessagesCopy.groupAnnouncementEmpty : raw
    }

    private var myGroupNicknameLabel: String {
        GroupNicknameDisplay.settingsValue(
            realName: app.user.name,
            myGroupNickname: prefs.myGroupNickname
        )
    }

    private var muteBinding: Binding<Bool> {
        Binding(
            get: { prefs.muteNotifications },
            set: { value in
                var next = prefs
                next.muteNotifications = value
                applyPrefs(next)
            }
        )
    }

    private var pinBinding: Binding<Bool> {
        Binding(
            get: { prefs.isPinned },
            set: { value in
                var next = prefs
                next.isPinned = value
                applyPrefs(next)
            }
        )
    }

    private var nicknamesBinding: Binding<Bool> {
        Binding(
            get: { prefs.showMemberNicknames },
            set: { value in
                var next = prefs
                next.showMemberNicknames = value
                applyPrefs(next)
            }
        )
    }
}
