//
//  ConversationDetailToolbarTitle.swift
//  坐标系
//
//  会话详情顶栏标题（可点进资料 / 俱乐部 / 活动）。
//

import SwiftUI
import CoordinateModels

struct ConversationDetailToolbarTitle: View {
    let conversation: ChatConversation
    let viewerName: String
    var onTap: (() -> Void)?

    var body: some View {
        let subtitle = conversation.navigationSubtitle(viewerName: viewerName)
        if let onTap {
            Button(action: onTap) {
                PlatformToolbarPrincipalCaption(
                    title: conversation.title,
                    subtitle: subtitle
                )
            }
            .platformToolbarPrincipalCapsuleStyle()
        } else {
            PlatformToolbarPrincipalCaption(
                title: conversation.title,
                subtitle: subtitle
            )
        }
    }
}
