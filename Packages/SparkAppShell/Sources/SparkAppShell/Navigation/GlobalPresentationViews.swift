// Module: SparkAppShell — Shared modal content for global presentation state.

import SparkPayments
import SwiftUI

struct GlobalSheetContent: View {
    let presentation: GlobalPresentation
    let onDismiss: () -> Void

    var body: some View {
        switch presentation {
        case .authRequired:
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text(
                        String(
                            localized: "shell.authRequired.title",
                            defaultValue: "需要登录",
                            comment: "Auth required sheet title"
                        )
                    )
                    .font(.title2.weight(.semibold))
                    Text(
                        String(
                            localized: "shell.authRequired.message",
                            defaultValue: "请先登录后再使用此功能。",
                            comment: "Auth required sheet message"
                        )
                    )
                    .foregroundStyle(.secondary)
                    Button(
                        String(localized: "shell.authRequired.ok", defaultValue: "好", comment: "Dismiss"),
                        action: onDismiss
                    )
                    .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .navigationTitle(
                    String(localized: "shell.authRequired.nav", defaultValue: "登录", comment: "Nav title")
                )
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        case .info, .paywall:
            EmptyView()
        }
    }
}

struct GlobalFullScreenContent: View {
    let presentation: GlobalPresentation
    let entitlementManager: EntitlementManager
    let onDismiss: () -> Void

    var body: some View {
        switch presentation {
        case .authRequired:
            EmptyView()
        case let .info(title, message):
            NavigationStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.title2.weight(.semibold))
                    Text(message)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(24)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(
                            String(localized: "shell.info.close", defaultValue: "关闭", comment: "Close"),
                            action: onDismiss
                        )
                    }
                }
            }
        case let .paywall(placement):
            PaywallView(
                entitlementManager: entitlementManager,
                placement: placement,
                onDismiss: onDismiss
            )
        }
    }
}
