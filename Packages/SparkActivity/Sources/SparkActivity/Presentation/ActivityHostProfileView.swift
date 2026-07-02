// Module: SparkActivity — Host person profile (push from discover feed).

import SparkDesignSystem
import SwiftUI

struct ActivityHostProfileRoute: Hashable, Sendable, Identifiable {
    let hostID: String
    let displayName: String

    var id: String { hostID }
}

struct ActivityHostProfileView: View {
    let route: ActivityHostProfileRoute
    let isAuthenticated: Bool
    let onOpenMessages: ((String) -> Void)?
    let onSignInRequired: (() -> Void)?

    init(
        route: ActivityHostProfileRoute,
        isAuthenticated: Bool = true,
        onOpenMessages: ((String) -> Void)? = nil,
        onSignInRequired: (() -> Void)? = nil
    ) {
        self.route = route
        self.isAuthenticated = isAuthenticated
        self.onOpenMessages = onOpenMessages
        self.onSignInRequired = onSignInRequired
    }

    var body: some View {
        SparkUnifiedIdentityContent(
            model: SparkUnifiedIdentityModel(
                id: route.hostID,
                displayName: route.displayName
            )
        ) {
            primaryAction
        }
        .navigationTitle(
            String(localized: "activity.host.profile.title", defaultValue: "用户资料", comment: "Host profile title")
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var primaryAction: some View {
        if isAuthenticated, let onOpenMessages {
            Button {
                onOpenMessages(route.hostID)
            } label: {
                Text(
                    String(
                        localized: "activity.host.profile.message",
                        defaultValue: "发消息",
                        comment: "Message host"
                    )
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        } else if !isAuthenticated, let onSignInRequired {
            Button(action: onSignInRequired) {
                Text(
                    String(
                        localized: "activity.host.profile.signInToMessage",
                        defaultValue: "登录后发消息",
                        comment: "Sign in to message host"
                    )
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview("Host profile") {
    NavigationStack {
        ActivityHostProfileView(
            route: ActivityHostProfileRoute(hostID: "host_hike", displayName: "阿乐"),
            onOpenMessages: { _ in }
        )
    }
}
