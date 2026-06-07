//
//  SparkApp.swift
//  Spark
//

import SwiftUI

@main
struct SparkApp: App {
    @UIApplicationDelegateAdaptor(SparkAppDelegate.self) private var appDelegate
    @State private var dependencies: AppDependencies?

    var body: some Scene {
        WindowGroup {
            Group {
                if let dependencies {
                    ContentView(dependencies: dependencies, appDelegate: appDelegate)
                        .environment(\.appDependencies, dependencies)
                } else {
                    ProgressView()
                }
            }
            .task {
                guard dependencies == nil else { return }
                dependencies = await CompositionRoot.bootstrapAsync()
            }
        }
    }
}
