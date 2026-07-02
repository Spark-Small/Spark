// Module: SparkAppShell — Shared modal content for global presentation state.

import SparkAuth
import SparkPayments
import SwiftUI

struct GlobalSheetContent: View {
    let presentation: GlobalPresentation
    @Bindable var authViewModel: AuthViewModel
    let onDismiss: () -> Void

    var body: some View {
        switch presentation {
        case .authRequired:
            LoginView(viewModel: authViewModel, onCancel: onDismiss)
        case .info, .paywall:
            EmptyView()
        }
    }
}

struct GlobalFullScreenContent: View {
    let presentation: GlobalPresentation
    @Bindable var authViewModel: AuthViewModel
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
