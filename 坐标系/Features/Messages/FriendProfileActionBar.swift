//
//  FriendProfileActionBar.swift
//  坐标系
//
//  通讯录资料卡底栏：发消息 / 通话（系统 Contacts 双主操作）。
//

import SwiftUI

struct FriendProfileActionBar: View {
    var onMessage: () -> Void
    var onCall: () -> Void

    var body: some View {
        DetailBottomActionBar {
            Button(MessagesCopy.friendAVCall, systemImage: "video", action: onCall)
                .activityDetailBottomSecondaryCTA()

            Button(MessagesCopy.friendSendMessage, systemImage: "message.fill", action: onMessage)
                .activityDetailBottomPrimaryCTA()
        }
        .labelStyle(.titleAndIcon)
    }
}
