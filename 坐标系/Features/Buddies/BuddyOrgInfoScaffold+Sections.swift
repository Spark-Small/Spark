//
//  BuddyOrgInfoScaffold+Sections.swift
//  坐标系
//
//  组织资料骨架：加入态分区与成员网格。
//

import SwiftUI
import CoordinateModels

extension BuddyOrgInfoScaffold {
    // MARK: - Circle joined sections

    @ViewBuilder
    var circleOverviewSection: some View {
        Section {
            if let onEnterChat {
                Button(action: onEnterChat) {
                    Label(BuddyOrgJoinCopy.enterChat, systemImage: "bubble.left.and.bubble.right.fill")
                }
            }

            if canRenameChat {
                Button {
                    showRenameSheet = true
                } label: {
                    LabeledContent(CircleGroupCopy.chatName, value: resolvedChatTitle)
                }
                .buttonStyle(.plain)
            } else {
                LabeledContent(CircleGroupCopy.chatName, value: resolvedChatTitle)
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
                Text(announcement)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
            .padding(.vertical, PlatformMetrics.hairlineSpacing)

            NavigationLink {
                if let circleConversationID {
                    CircleGroupManageView(
                        conversationID: circleConversationID,
                        displayName: displayName,
                        prefs: prefs,
                        onPrefsChange: onPrefsChange,
                        onDissolve: {
                            onDissolveCircle?()
                        }
                    )
                }
            } label: {
                Text(CircleGroupCopy.manage)
            }
            .disabled(circleConversationID == nil)
        }
    }

    // MARK: - Circle joined sections (continued)

    @ViewBuilder
    var circleChatPrefsSection: some View {
        Section {
            // 未接线时不展示死入口，避免点进「即将开放」。
            if let onSearchChat {
                Button(action: onSearchChat) {
                    Text(CircleGroupCopy.searchChat)
                }
            }

            Toggle(CircleGroupCopy.muteNotifications, isOn: muteBinding)

            if prefs.muteNotifications {
                NavigationLink {
                    CircleMutedNotifySettingsView(
                        prefs: prefs,
                        onPrefsChange: onPrefsChange
                    )
                } label: {
                    Text(CircleGroupCopy.mutedNotify)
                }
            }

            Toggle(CircleGroupCopy.pinChat, isOn: pinBinding)
        }
    }

    @ViewBuilder
    var circleIdentitySection: some View {
        Section {
            groupNicknameLink
            Toggle(CircleGroupCopy.showMemberNicknames, isOn: nicknamesBinding)
        }
    }

    @ViewBuilder
    var circleClearHistorySection: some View {
        Section {
            Button(CircleGroupCopy.clearHistory, role: .destructive) {
                confirmClearHistory = true
            }
            .disabled(onClearChatHistory == nil)
        }
    }

    @ViewBuilder
    var circleLeaveSection: some View {
        Section {
            Button(leaveTitle, role: .destructive) {
                confirmLeave = true
            }
        }
    }

    // MARK: - Guild joined sections

    @ViewBuilder
    var joinedInfoSection: some View {
        Section {
            HStack {
                Text(CircleGroupCopy.qrCode)
                Spacer()
                Image(systemName: "qrcode")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(CircleGroupCopy.qrCode)

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(CircleGroupCopy.announcement)
                Text(announcement)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
            .padding(.vertical, PlatformMetrics.hairlineSpacing)

            if let onEnterChat {
                Button(action: onEnterChat) {
                    Label(BuddyOrgJoinCopy.enterChat, systemImage: "bubble.left.and.bubble.right.fill")
                }
            }
        }
    }

    @ViewBuilder
    var joinedPreferencesSection: some View {
        Section {
            Toggle(CircleGroupCopy.muteNotifications, isOn: muteBinding)
            Toggle(pinTitle, isOn: pinBinding)
            groupNicknameLink
            Toggle(CircleGroupCopy.showMemberNicknames, isOn: nicknamesBinding)
        }
    }

    @ViewBuilder
    var joinedManagementSection: some View {
        Section {
            Button(leaveTitle, role: .destructive) {
                confirmLeave = true
            }
        }
    }
}
