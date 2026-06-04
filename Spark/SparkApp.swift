//
//  SparkApp.swift
//  Spark
//

import SparkActivity
import SwiftUI

@main
struct SparkApp: App {
    @UIApplicationDelegateAdaptor(SparkAppDelegate.self) private var appDelegate

    init() {
        CompositionRoot.bootstrap()
        ActivityNotificationRegistrar.registerIfNeeded() // Phase 16: no-op until user enables 活动提醒
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appDelegate: appDelegate)
        }
    }
}
