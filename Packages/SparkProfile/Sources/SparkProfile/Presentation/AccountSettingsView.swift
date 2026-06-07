// Module: SparkProfile — Aggregated account and privacy settings.

import SparkDesignSystem
import SparkNotifications
import SwiftUI

public struct AccountSettingsView: View {
    let onOpenNotificationSettings: () -> Void
    let onOpenPaywall: () -> Void

    public init(
        onOpenNotificationSettings: @escaping () -> Void,
        onOpenPaywall: @escaping () -> Void
    ) {
        self.onOpenNotificationSettings = onOpenNotificationSettings
        self.onOpenPaywall = onOpenPaywall
    }

    public var body: some View {
        List {
            Section(
                String(
                    localized: "profile.settings.notifications.section",
                    defaultValue: "通知",
                    comment: "Notifications section"
                )
            ) {
                Button(action: onOpenNotificationSettings) {
                    Label(
                        String(
                            localized: "notifications.settings.title",
                            defaultValue: "通知设置",
                            comment: "Notification settings"
                        ),
                        systemImage: "bell"
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.sparkPressable)
                .sparkSemanticListRow()
            }

            Section(
                String(
                    localized: "profile.section.premium",
                    defaultValue: "订阅",
                    comment: "Premium section"
                )
            ) {
                Button(action: onOpenPaywall) {
                    Label(
                        String(localized: "paywall.cta", defaultValue: "Premium", comment: "Premium CTA"),
                        systemImage: "sparkles"
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.sparkPressable)
                .sparkSemanticListRow()
                if let subscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions") {
                    Link(destination: subscriptionsURL) {
                        Label(
                            String(
                                localized: "payments.manageSubscriptions",
                                defaultValue: "管理订阅",
                                comment: "Manage subscriptions"
                            ),
                            systemImage: "creditcard"
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .sparkSemanticListRow()
                }
            }
        }
        .sparkSemanticListChrome()
        .navigationTitle(
            String(
                localized: "profile.accountSettings.title",
                defaultValue: "账号设置",
                comment: "Account settings title"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AccountSettingsView(
            onOpenNotificationSettings: {},
            onOpenPaywall: {}
        )
    }
}
