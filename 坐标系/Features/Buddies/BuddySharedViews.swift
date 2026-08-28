//
//  BuddySharedViews.swift
//  坐标系
//

import SwiftUI

struct TagFlow: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PlatformMetrics.minContentGap) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .platformGlassTag()
                }
            }
        }
    }
}

struct BuddyDetailActionBar: View {
    var inviteEnabled = true
    var inviteTitle = BuddyDetailCopy.invite
    var greetTitle = BuddyDetailCopy.greet
    /// 工会 / 语音厅入口：预约按钮带系统图标，强调转化
    var emphasizeInvite = false
    var onGreet: () -> Void
    var onInvite: () -> Void

    var body: some View {
        DetailBottomActionBar {
            Button(greetTitle, action: onGreet)
                .activityDetailBottomSecondaryCTA()

            if emphasizeInvite {
                Button(action: onInvite) {
                    Label(inviteTitle, systemImage: "bolt.fill")
                }
                .activityDetailBottomPrimaryCTA()
                .disabled(!inviteEnabled)
            } else {
                Button(inviteTitle, action: onInvite)
                    .activityDetailBottomPrimaryCTA()
                    .disabled(!inviteEnabled)
            }
        }
    }
}
