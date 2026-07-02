// Module: SparkAuth — Shared legal consent footer for auth screens.

import SparkCore
import SparkDesignSystem
import SwiftUI

struct AuthLegalFooter: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 4) {
            Text(LoginCopy.legalLead)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                legalLinkButton(
                    title: LoginCopy.termsOfService,
                    url: SparkLegalLinks.termsOfServiceURL,
                    accessibilityHint: LoginCopy.termsHint
                )
                Text(LoginCopy.legalAnd)
                    .foregroundStyle(.secondary)
                legalLinkButton(
                    title: LoginCopy.privacyPolicy,
                    url: SparkLegalLinks.privacyPolicyURL,
                    accessibilityHint: LoginCopy.privacyHint
                )
            }
        }
        .font(.footnote)
    }

    private func legalLinkButton(title: String, url: URL, accessibilityHint: String) -> some View {
        Button {
            openURL(url)
        } label: {
            Text(title)
        }
        .buttonStyle(.plain)
        .tint(.accentColor)
        .accessibilityHint(accessibilityHint)
    }
}
