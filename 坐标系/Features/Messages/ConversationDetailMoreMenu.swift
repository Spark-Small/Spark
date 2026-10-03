//
//  ConversationDetailMoreMenu.swift
//  坐标系
//
//  会话详情「更多」：私聊 = 资料 / 置顶 / 免打扰 / 清空 / 删除；
//  活动群 = 群详情 + 退出·解散（置顶 / 免打扰 / 清空 / 活动在群详情）；
//  其他群 = 群详情 / 置顶 / 举报 / 退出·解散。
//

import SwiftUI
import CoordinateModels

struct ConversationDetailMoreMenu: View {
    let conversation: ChatConversation
    let isOwnedByViewer: Bool
    var hasBuddyProfile: Bool
    var hasCircleInfo: Bool
    var onTogglePin: () -> Void
    var onToggleMute: () -> Void
    var onClearHistory: () -> Void
    var onCircleInfo: () -> Void
    var onGroupManage: () -> Void
    var onViewProfile: () -> Void
    var onReport: () -> Void
    var onDissolveGroup: () -> Void
    var onLeavePeerGroup: () -> Void
    var onCancelRegistration: () -> Void
    var onLeaveCircle: () -> Void
    var onDeleteConversation: () -> Void

    var body: some View {
        Menu {
            if conversation.isActivityGroup {
                activityGroupItems
            } else if conversation.isGroup {
                otherGroupItems
            } else if conversation.kind == .direct {
                directItems
            } else {
                noticeItems
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel(MessagesCopy.more)
    }

    /// 活动群：仅入口与破坏性动作（对齐信息群「详情 / 离开」）
    @ViewBuilder
    private var activityGroupItems: some View {
        Button(MessagesCopy.groupDetailTitle, systemImage: "info.circle", action: onGroupManage)
        Divider()
        destructiveGroupActions
    }

    @ViewBuilder
    private var otherGroupItems: some View {
        Button(MessagesCopy.groupDetailTitle, systemImage: "info.circle", action: onGroupManage)
        if conversation.isCircleGroup, hasCircleInfo {
            Button(MessagesCopy.circleInfo, systemImage: "person.3", action: onCircleInfo)
        }
        pinButton
        Divider()
        Button(MessagesCopy.reportUser, systemImage: "exclamationmark.bubble", action: onReport)
        destructiveGroupActions
    }

    @ViewBuilder
    private var directItems: some View {
        Button(MessagesCopy.viewProfile, systemImage: "person.crop.circle", action: onViewProfile)
            .disabled(!hasBuddyProfile)
        pinButton
        muteButton
        Divider()
        Button(
            MessagesCopy.groupClearHistory,
            systemImage: "eraser",
            role: .destructive,
            action: onClearHistory
        )
        Button(
            MessagesCopy.deleteConversation,
            systemImage: "trash",
            role: .destructive,
            action: onDeleteConversation
        )
    }

    @ViewBuilder
    private var noticeItems: some View {
        pinButton
        muteButton
        Divider()
        Button(
            MessagesCopy.deleteConversation,
            systemImage: "trash",
            role: .destructive,
            action: onDeleteConversation
        )
    }

    private var pinButton: some View {
        Button(
            conversation.isPinned ? MessagesCopy.unpinConversation : MessagesCopy.pinConversation,
            systemImage: conversation.isPinned ? "pin.slash" : "pin",
            action: onTogglePin
        )
    }

    private var muteButton: some View {
        Button(
            conversation.isMuted ? MessagesCopy.muteOff : MessagesCopy.muteOn,
            systemImage: conversation.isMuted ? "bell" : "bell.slash",
            action: onToggleMute
        )
    }

    @ViewBuilder
    private var destructiveGroupActions: some View {
        if conversation.isActivityGroup {
            if isOwnedByViewer {
                Button(MessagesCopy.dissolveGroup, systemImage: "trash", role: .destructive, action: onDissolveGroup)
            } else {
                Button(
                    MessagesCopy.leaveGroup,
                    systemImage: "rectangle.portrait.and.arrow.right",
                    role: .destructive,
                    action: onCancelRegistration
                )
            }
        } else if conversation.isPeerGroup {
            if isOwnedByViewer {
                Button(MessagesCopy.dissolveGroup, systemImage: "trash", role: .destructive, action: onDissolveGroup)
            } else {
                Button(
                    MessagesCopy.leaveGroup,
                    systemImage: "rectangle.portrait.and.arrow.right",
                    role: .destructive,
                    action: onLeavePeerGroup
                )
            }
        } else if conversation.isCircleGroup {
            Button(
                MessagesCopy.leaveGroup,
                systemImage: "rectangle.portrait.and.arrow.right",
                role: .destructive,
                action: onLeaveCircle
            )
        } else {
            Button(
                MessagesCopy.deleteConversation,
                systemImage: "trash",
                role: .destructive,
                action: onDeleteConversation
            )
        }
    }
}
