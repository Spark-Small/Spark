//
//  CommunityView+Toolbar.swift
//  坐标系
//
//  广场顶栏：静音铃（仅 denied）· 发分享。
//  系统搜索按钮：DefaultToolbarItem + `.minimize` 放 **bottomBar**（Apple 文档口径）；
//  勿放 topBarTrailing（与 Tab 根组合关闭时会死循环）。
//

import SwiftUI

extension CommunityFeedStack {
    var notificationsMuted: Bool {
        notificationAuth == .denied
    }

    @ToolbarContentBuilder
    var feedToolbar: some ToolbarContent {
        if notificationsMuted {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    NotificationService.openSystemSettings()
                } label: {
                    Image(systemName: "bell.slash")
                }
                .platformNavigationBarItemChrome()
                .accessibilityLabel(CommunityDynamicsCopy.notificationsMutedAccessibility)
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(CommunityBrowseCopy.composeAccessibility, systemImage: "plus") {
                model.presentation.beginCompose()
            }
            .platformNavigationBarItemChrome()
        }

        // iPhone：最小化搜索属底栏（searchToolbarBehavior(.minimize) 官方示例同族）。
        DefaultToolbarItem(kind: .search, placement: .bottomBar)
    }

    func refreshNotificationAuth() async {
        notificationAuth = await NotificationService.authorizationStatus()
    }

    func turnOnNotifications() async {
        let granted = await NotificationService.requestAuthorization()
        await refreshNotificationAuth()
        if !granted {
            NotificationService.openSystemSettings()
        } else {
            feedPreferences.dismissNotifyBanner()
        }
    }
}
