// Module: Spark App — SwiftUI environment for composition-root dependencies.

import SwiftUI

private struct AppDependenciesKey: EnvironmentKey {
    // REASONING: Force injection from ContentView; previews pass explicit mocks.
    static let defaultValue: AppDependencies? = nil
}

extension EnvironmentValues {
    var appDependencies: AppDependencies? {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }

    /// Force-injected dependencies from `ContentView`; traps in debug if missing.
    var requireAppDependencies: AppDependencies {
        guard let appDependencies else {
            preconditionFailure("AppDependencies must be injected from ContentView")
        }
        return appDependencies
    }
}
