// Module: SparkAuth — Native Form phone OTP rows (grouped inset list style).

import SparkDesignSystem
import SwiftUI

enum LoginFormField: Hashable {
    case phone
    case otp
}

/// Phone number row — native `Form` `TextField` with a fixed-width trailing accessory overlay.
struct LoginPhoneNumberFieldRow: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState.Binding var focusedField: LoginFormField?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TextField(
            String(localized: "auth.login.phone", defaultValue: "手机号", comment: "Phone field"),
            text: $viewModel.phoneNumber
        )
        .textContentType(.telephoneNumber)
        .keyboardType(.phonePad)
        .submitLabel(.next)
        .focused($focusedField, equals: .phone)
        .accessibilityLabel(
            String(
                localized: "auth.login.phone.a11y",
                defaultValue: "手机号",
                comment: "Phone number field accessibility label"
            )
        )
        .padding(.trailing, viewModel.showsPhoneTrailingAccessory ? SparkAuthLayoutMetrics.phoneTrailingSlotWidth : 0)
        .overlay(alignment: .trailing) {
            if viewModel.showsPhoneTrailingAccessory {
                LoginOTPTrailingControl(viewModel: viewModel)
                    .frame(width: SparkAuthLayoutMetrics.phoneTrailingSlotWidth, alignment: .trailing)
            }
        }
        .sparkAuthFormCredentialRow()
        .onChange(of: viewModel.normalizedPhoneNumber) { previous, current in
            guard previous != current, !previous.isEmpty else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                viewModel.resetPhoneOTPEntry()
            }
        }
    }
}

/// Trailing send / cooldown / loading affordance on the phone row.
private struct LoginOTPTrailingControl: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        Group {
            if viewModel.isRequestingOTP {
                ProgressView()
                    .accessibilityLabel(
                        String(
                            localized: "auth.login.otp.requesting.a11y",
                            defaultValue: "正在发送验证码",
                            comment: "OTP request loading a11y"
                        )
                    )
            } else if viewModel.otpCooldownSeconds > 0 {
                Text(resendCountdownText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityLabel(
                        String(
                            localized: "auth.login.otp.resendIn.a11y",
                            defaultValue: "重新发送验证码",
                            comment: "OTP resend countdown accessibility label"
                        )
                    )
                    .accessibilityValue(resendCountdownText)
            } else {
                Button {
                    Task { await viewModel.requestOTPTapped() }
                } label: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    String(
                        localized: "auth.login.otp.send.a11y",
                        defaultValue: "发送验证码",
                        comment: "Send OTP via continue arrow"
                    )
                )
            }
        }
        .frame(
            minWidth: SparkLayoutMetrics.minimumTouchTarget,
            minHeight: SparkLayoutMetrics.minimumTouchTarget,
            alignment: .trailing
        )
    }

    private var resendCountdownText: String {
        String(
            format: String(
                localized: "auth.login.otp.resendIn.format",
                defaultValue: "%lld 秒",
                comment: "OTP resend countdown; argument is seconds remaining"
            ),
            viewModel.otpCooldownSeconds
        )
    }
}

/// OTP row — appears as a second native `Form` row after code is sent.
struct LoginOTPFieldRow: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState.Binding var focusedField: LoginFormField?

    var body: some View {
        TextField(
            String(localized: "auth.login.otp", defaultValue: "验证码", comment: "OTP field"),
            text: $viewModel.otpCode
        )
        .textContentType(.oneTimeCode)
        .keyboardType(.numberPad)
        .submitLabel(.go)
        .focused($focusedField, equals: .otp)
        .accessibilityLabel(
            String(
                localized: "auth.login.otp.a11y",
                defaultValue: "验证码",
                comment: "OTP field accessibility label"
            )
        )
        .sparkAuthFormCredentialRow()
        .onSubmit {
            Task { await viewModel.signInWithPhoneOTPTapped() }
        }
    }
}

#if DEBUG
#Preview("Phone row — send") {
    @Previewable @FocusState var focusedField: LoginFormField?

    Form {
        Section {
            LoginPhoneNumberFieldRow(
                viewModel: AuthPreviewSupport.phoneReadyViewModel(),
                focusedField: $focusedField
            )
        }
    }
}

#Preview("Phone row — cooldown") {
    @Previewable @FocusState var focusedField: LoginFormField?

    Form {
        Section {
            LoginPhoneNumberFieldRow(
                viewModel: AuthPreviewSupport.phoneCooldownViewModel(),
                focusedField: $focusedField
            )
            LoginOTPFieldRow(
                viewModel: AuthPreviewSupport.phoneCooldownViewModel(),
                focusedField: $focusedField
            )
        }
    }
}

#Preview("Phone + OTP rows") {
    @Previewable @FocusState var focusedField: LoginFormField?

    Form {
        Section {
            LoginPhoneNumberFieldRow(
                viewModel: AuthPreviewSupport.phoneOTPExpandedViewModel(),
                focusedField: $focusedField
            )
            LoginOTPFieldRow(
                viewModel: AuthPreviewSupport.phoneOTPExpandedViewModel(),
                focusedField: $focusedField
            )
        }
    }
}
#endif
