// Module: SparkAuth — PIPL consent before collecting phone or third-party sign-in.

import SparkCore
import SwiftUI

struct LoginLegalConsentSection: View {
    @Binding var isAccepted: Bool

    var body: some View {
        Toggle(isOn: $isAccepted) {
            consentLabel
        }
        .font(.footnote)
        .accessibilityHint(
            String(
                localized: "auth.login.legalConsent.hint",
                defaultValue: "同意后方可登录或获取验证码",
                comment: "Legal consent toggle hint"
            )
        )
        .onChange(of: isAccepted) { _, accepted in
            if accepted {
                AuthTelemetry.legalConsentAccepted()
            }
        }
    }

    private var consentLabel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(
                String(
                    localized: "auth.login.legalConsent.lead",
                    defaultValue: "我已阅读并同意",
                    comment: "Legal consent lead-in"
                )
            )
            HStack(spacing: 0) {
                Link(
                    String(
                        localized: "auth.login.legalConsent.terms",
                        defaultValue: "《用户协议》",
                        comment: "Terms of service link"
                    ),
                    destination: SparkLegalLinks.termsOfServiceURL
                )
                Text(
                    String(
                        localized: "auth.login.legalConsent.and",
                        defaultValue: "与",
                        comment: "Legal consent conjunction"
                    )
                )
                Link(
                    String(
                        localized: "auth.login.legalConsent.privacy",
                        defaultValue: "《隐私政策》",
                        comment: "Privacy policy link"
                    ),
                    destination: SparkLegalLinks.privacyPolicyURL
                )
            }
        }
        .foregroundStyle(.secondary)
    }
}

#if DEBUG
#Preview {
    Form {
        Section {
            LoginLegalConsentSection(isAccepted: .constant(false))
        }
    }
}
#endif
