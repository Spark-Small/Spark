//
//  ActivityEngagementEnvironment.swift
//  坐标系
//

import SwiftUI

private struct ActivityEngagementStoreKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: ActivityEngagementStore = MainActor.assumeIsolated {
        AppComposition.activityEngagementStore
    }
}

extension EnvironmentValues {
    var activityEngagementStore: ActivityEngagementStore {
        get { self[ActivityEngagementStoreKey.self] }
        set { self[ActivityEngagementStoreKey.self] = newValue }
    }
}
