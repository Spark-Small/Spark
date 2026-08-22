//
//  MessagesInviteFriends.swift
//  坐标系
//
//  邀请好友：挂在消息 / 通讯录（社交入口），系统分享面板。
//

import SwiftUI
import UIKit

enum MessagesInviteFriends {
    @MainActor
    static func presentSystemShare() {
        let activityVC = UIActivityViewController(
            activityItems: [MessagesCopy.inviteFriendsShareText],
            applicationActivities: nil
        )
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              var top = scene.windows.first(where: \.isKeyWindow)?.rootViewController
                ?? scene.windows.first?.rootViewController
        else { return }
        while let presented = top.presentedViewController {
            top = presented
        }
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(
                x: top.view.bounds.midX,
                y: top.view.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        top.present(activityVC, animated: true)
    }
}
