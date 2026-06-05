// Module: SparkAppShell — Activity tab account / premium toolbar.

import SparkAuth
import SparkPayments
import SwiftUI

struct SparkMainTabAccountToolbar: ToolbarContent {
    @Bindable var authViewModel: AuthViewModel
    @Bindable var router: AppRouter
    @Bindable var entitlementManager: EntitlementManager
    let paywallRouter: PaywallRouter

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if SparkFeatureFlags.isPremiumPaywallEnabled, !entitlementManager.hasPremium {
                Button(
                    String(localized: "paywall.cta", defaultValue: "Premium", comment: "Premium CTA")
                ) {
                    paywallRouter.presentPaywall(placement: .activity)
                }
                .accessibilityLabel(
                    String(localized: "paywall.cta.a11y", defaultValue: "查看订阅", comment: "Premium a11y")
                )
            }

            Button(
                String(localized: "auth.signOut", defaultValue: "退出登录", comment: "Sign out")
            ) {
                Task {
                    await authViewModel.signOutTapped()
                    router.resetAfterSignOut()
                }
            }
        }
    }
}
