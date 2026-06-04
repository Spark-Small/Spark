// Module: SparkAppShell — Bridges PaywallRouting to AppRouter presentation state.

import Foundation
import SparkPayments

@MainActor
public final class PaywallRouter: PaywallRouting {
    private let appRouter: AppRouter

    public init(appRouter: AppRouter) {
        self.appRouter = appRouter
    }

    public func presentPaywall(placement: PaywallPlacement) {
        appRouter.globalFullScreenCover = .paywall(placement: placement)
    }

    public func dismissPaywall() {
        appRouter.dismissGlobalPresentation()
    }
}
