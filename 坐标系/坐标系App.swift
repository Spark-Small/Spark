//
//  坐标系App.swift
//  坐标系
//
//  Created by NMD on 2026/7/15.
//

import SwiftUI

@main
struct 坐标系App: App {
    init() {
        AppPersistence.refreshCatalogIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    #if DEBUG
                    LocalCommercialSelfTests.runCriticalChecks()
                    #endif
                }
        }
    }
}
