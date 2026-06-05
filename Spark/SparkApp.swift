//
//  SparkApp.swift
//  Spark
//

import SwiftUI

@main
struct SparkApp: App {
    @UIApplicationDelegateAdaptor(SparkAppDelegate.self) private var appDelegate

    init() {
        CompositionRoot.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appDelegate: appDelegate)
        }
    }
}
