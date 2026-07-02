// Module: SparkAuth — Shared form button chrome for auth screens.

import SparkDesignSystem
import SwiftUI

extension View {
    func loginActionRowChrome() -> some View {
        listRowInsets(SparkAuthLayout.authActionRowInsets)
            .listRowBackground(Color.clear)
    }

    func loginPrimaryButtonChrome(tint: Color? = nil) -> some View {
        modifier(AuthPrimaryButtonChromeModifier(tint: tint))
    }

    /// Apple HIG: black/white fill with contrasting label — not `.borderedProminent` tint (breaks in dark mode).
    func loginAppleSignInButtonChrome(colorScheme: ColorScheme) -> some View {
        let background = AuthBrandColor.appleSignInBackground(for: colorScheme)
        let foreground = AuthBrandColor.appleSignInForeground(for: colorScheme)
        return foregroundStyle(foreground)
            .buttonStyle(.plain)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .frame(height: SparkAuthLayout.signInButtonMinHeight)
            .background(
                background,
                in: RoundedRectangle(
                    cornerRadius: SparkAuthLayout.signInButtonCornerRadius,
                    style: .continuous
                )
            )
    }

    func loginSecondaryButtonChrome() -> some View {
        buttonStyle(.bordered)
            .controlSize(.large)
            .frame(height: SparkAuthLayout.signInButtonMinHeight)
    }
}

private struct AuthPrimaryButtonChromeModifier: ViewModifier {
    let tint: Color?

    func body(content: Content) -> some View {
        Group {
            if let tint {
                content.tint(tint)
            } else {
                content
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(height: SparkAuthLayout.signInButtonMinHeight)
    }
}
