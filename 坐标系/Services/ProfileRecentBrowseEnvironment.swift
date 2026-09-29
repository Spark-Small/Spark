//
//  ProfileRecentBrowseEnvironment.swift
//  坐标系
//

import SwiftUI

private struct ProfileRecentBrowseStoreKey: EnvironmentKey {
    nonisolated(unsafe) static var defaultValue: ProfileRecentBrowseStore = MainActor.assumeIsolated {
        ProfileRecentBrowseStore()
    }
}

extension EnvironmentValues {
    var profileRecentBrowseStore: ProfileRecentBrowseStore {
        get { self[ProfileRecentBrowseStoreKey.self] }
        set { self[ProfileRecentBrowseStoreKey.self] = newValue }
    }
}
