//
//  ConversationDetailMoreMenu.swift
//  坐标系
//
//  会话详情「更多」菜单：显式回调，不持有域 Model。
//

import SwiftUI
import CoordinateModels

struct ConversationDetailMoreMenu: View {
    let conversation: ChatConversation
    let isOwnedByViewer: Bool
    var hasBuddyProfile: Bool
    var hasRelatedActivity: Bool
    var hasCircleInfo: Bool
    var onTogglePin: () -> Void
    var onToggleMute: () -> Void
    var onCallHistory: () -> Void
    var onCircleInfo: () -> Void
    var onGroupManage: () -> Void
    var onActivityDetail: () -> Void
    var onViewProfile: () -> Void
    var onReport: () -> Void
    var onBlock: () -> Void
    var onDissolveOrLeave: () -> Void
    var onCancelRegistration: () -> Void
    var onLeaveCircle: () -> Void
    var onDeleteConversation: () -> Void

    var body: some View {
        Menu {
            Button(
                conversation.isPinned ? MessagesCopy.unpinConversation : MessagesCopy.pinConversation,
                systemImage: conversation.isPinned ? "pin.slash" : "pin",
                action: onTogglePin
            )
            Button(
                conversation.isMuted ? MessagesCopy.muteOff : MessagesCopy.muteOn,
                systemImage: conversation.isMuted ? "bell" : "bell.slash",
                action: onToggleMute
            )
            if conversation.kind != .notice {
                Button(MessagesCopy.callHistoryTitle, systemImage: "clock.arrow.circlepath", action: onCallHistory)
            }
            if conversation.isGroup {
                if conversation.isCircleGroup, hasCircleInfo {
                    Button("圈子信息", systemImage: "info.circle", action: onCircleInfo)
                }
                Button(MessagesCopy.groupManage, systemImage: "gearshape", action: onGroupManage)
            }
            if conversation.kind == .activity {
                Button(MessagesCopy.activityDetail, systemImage: "calendar", action: onActivityDetail)
                    .disabled(!hasRelatedActivity)
            }
            if conversation.kind == .direct {
                Button(MessagesCopy.viewProfile, systemImage: "person.crop.circle", action: onViewProfile)
                    .disabled(!hasBuddyProfile)
                Button(MessagesCopy.reportUser, systemImage: "exclamationmark.bubble", action: onReport)
                Button(MessagesCopy.blockUser, systemImage: "hand.raised", role: .destructive, action: onBlock)
            } else if conversation.kind != .notice {
                Button(MessagesCopy.reportUser, systemImage: "exclamationmark.bubble", action: onReport)
            }
            if conversation.isActivityGroup {
                if isOwnedByViewer {
                    Button(MessagesCopy.dissolveGroup, systemImage: "trash", role: .destructive, action: onDissolveOrLeave)
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
                    Button(MessagesCopy.dissolveGroup, systemImage: "trash", role: .destructive, action: onDissolveOrLeave)
                } else {
                    Button(MessagesCopy.leaveGroup, systemImage: "rectangle.portrait.and.arrow.right", role: .destructive, action: onDissolveOrLeave)
                }
            } else if conversation.isCircleGroup {
                Button(MessagesCopy.leaveGroup, systemImage: "rectangle.portrait.and.arrow.right", role: .destructive, action: onLeaveCircle)
            } else {
                Button(MessagesCopy.deleteConversation, systemImage: "trash", role: .destructive, action: onDeleteConversation)
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel(MessagesCopy.more)
    }
}
