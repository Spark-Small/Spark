//
//  CommunityView+Toolbar.swift
//  坐标系
//
//  广场顶栏：静音铃（仅 denied）· 发帖。无搜索入口。
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
