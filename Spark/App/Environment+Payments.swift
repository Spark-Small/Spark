// Module: Spark App — SwiftUI environment for paywall routing.

import SparkAppShell
import SparkPayments
import SwiftUI

private struct PaywallRoutingEnvironmentKey: EnvironmentKey {
    @MainActor
    static var defaultValue: PaywallRouter {
        PaywallRouter(appRouter: AppRouter())
    }
}

public extension EnvironmentValues {
    @MainActor
    var paywallRouter: PaywallRouter {
        get { self[PaywallRoutingEnvironmentKey.self] }
        set { self[PaywallRoutingEnvironmentKey.self] = newValue }
    }
}
