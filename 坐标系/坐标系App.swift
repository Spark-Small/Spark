//
//  坐标系App.swift
//  坐标系
//
//  Created by NMD on 2026/7/15.
//

import SwiftUI
import UserNotifications

@main
struct 坐标系App: App {
    init() {
        AppNotificationRouter.shared.install()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
