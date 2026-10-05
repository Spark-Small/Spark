//
//  ConversationDetailMoreMenu.swift
//  坐标系
//
//  会话详情「更多」：私聊 = 资料 / 置顶 / 免打扰 / 清空 / 删除；
//  群（活动/俱乐部/同伴）= 群详情 + 置顶 / 免打扰（与群详情 Toggle 同源）+ 清空 + 退出·解散。
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
    /// 私聊：请对方形象认证（需自己已认证；本机发文，不假服务端状态）。
    var onAskPhotoVerification: (() -> Void)? = nil
    var onReport: () -> Void
    var onDissolveGroup: () -> Void
    var onLeavePeerGroup: () -> Void
    /// 退出活动群聊（不取消报名）。
    var onLeaveActivityGroup: () -> Void
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

    /// 活动群：快捷开关与群详情 Toggle 同源（`conversation.isMuted` / `isPinned`）。
    @ViewBuilder
    private var activityGroupItems: some View {
        Button(MessagesCopy.groupDetailTitle, systemImage: "info.circle", action: onGroupManage)
        pinButton
        muteButton
        Divider()
        clearHistoryButton
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
        muteButton
        Divider()
        Button(MessagesCopy.reportUser, systemImage: "exclamationmark.bubble", action: onReport)
        clearHistoryButton
        Divider()
        destructiveGroupActions
    }

    @ViewBuilder
    private var directItems: some View {
        Button(MessagesCopy.viewProfile, systemImage: "person.crop.circle", action: onViewProfile)
            .disabled(!hasBuddyProfile)
        if let onAskPhotoVerification {
            Button(
                ProfilePhotoVerificationRequest.menuTitle,
                systemImage: "person.crop.circle.badge.checkmark",
                action: onAskPhotoVerification
            )
        }
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

    private var clearHistoryButton: some View {
        Button(
            MessagesCopy.groupClearHistory,
            systemImage: "eraser",
            role: .destructive,
            action: onClearHistory
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
                    action: onLeaveActivityGroup
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
