//
//  坐标系App.swift
//  坐标系
//
//  Created by NMD on 2026/7/15.
//

import SwiftData
import SwiftUI
import TipKit
import UserNotifications

@main
struct 坐标系App: App {
    private let modelContainer: ModelContainer

    init() {
        AppNotificationRouter.shared.install()
        AppTips.configure()

        do {
            modelContainer = try ModelContainer(for: RecentBrowseItem.self)
        } catch {
            fatalError("SwiftData ModelContainer failed: \(error)")
        }
        ProfileRecentBrowseStore.shared.attach(container: modelContainer)
        MembershipStore.shared.startListeningForTransactions()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await MembershipStore.shared.refreshEntitlement()
                }
        }
        .modelContainer(modelContainer)
    }
}
