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
import CoordinateModels

@main
struct 坐标系App: App {
    private let modelContainer: ModelContainer
    @State private var persistenceHealth = AppPersistenceHealth()

    init() {
        AppNotificationRouter.shared.install()
        AppTips.configure()

        let health = AppPersistenceHealth()
        do {
            modelContainer = try AppSwiftDataContainer.makeProduction()
        } catch {
            // Apple: 磁盘满 / 库损坏时勿 fatalError；降级内存容器并提示用户可恢复。
            assertionFailure("SwiftData ModelContainer failed: \(error)")
            do {
                modelContainer = try AppSwiftDataContainer.makeInMemory()
                health.markEphemeralFallback(error: error)
            } catch {
                preconditionFailure("In-memory ModelContainer also failed: \(error)")
            }
        }
        _persistenceHealth = State(initialValue: health)
        PersistenceWriteFailureReporter.bind(health)

        AppComposition.profileRecentBrowseStore.attach(container: modelContainer)
        SwiftDataSnapshotRegistry.attach(container: modelContainer)
        AppComposition.membershipStore.startListeningForTransactions()
    }

    var body: some Scene {
        WindowGroup {
            PlatformChromeRoot {
                ContentView()
                    .environment(persistenceHealth)
                    .environment(AppComposition.greetingWeatherStore)
                    .environment(AppComposition.locationService)
                    .task {
                        await AppComposition.membershipStore.refreshEntitlement()
                    }
            }
        }
        .modelContainer(modelContainer)
    }
}
