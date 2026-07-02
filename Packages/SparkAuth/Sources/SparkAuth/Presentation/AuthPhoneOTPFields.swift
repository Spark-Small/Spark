// Module: SparkAuth — Shared phone + SMS OTP fields (login / password reset).

import SparkDesignSystem
import SwiftUI

enum AuthPhoneOTPFocusField: Hashable {
    case phone
    case verificationCode
    case newPassword
}

/// Phone number row with optional send-OTP arrow, plus SMS verification code row.
struct AuthPhoneOTPFields: View {
    @Binding var phone: String
    @Binding var verificationCode: String
    @FocusState.Binding var focusedField: AuthPhoneOTPFocusField?

    let phonePlaceholder: String
    let verificationCodePlaceholder: String
    let sendCodeAccessibilityLabel: String
    let otpSent: Bool
    let showsSendArrow: Bool
    let isSendingOTP: Bool
    let resendSecondsRemaining: Int
    let isInteractionDisabled: Bool
    let onPhoneChange: () -> Void
    let onVerificationCodeChange: () -> Void
    let onSendOTP: () async -> Void

    var body: some View {
        Group {
            phoneNumberRow
            if otpSent {
                verificationCodeRow
            }
        }
    }

    private var showsPhoneTrailingAccessory: Bool {
        resendSecondsRemaining > 0 || showsSendArrow
    }

    private var phoneNumberRow: some View {
        TextField(phonePlaceholder, text: $phone)
            .keyboardType(.phonePad)
            .textContentType(.telephoneNumber)
            .authTextFieldChrome(focus: $focusedField, field: .phone)
            .padding(.trailing, showsPhoneTrailingAccessory ? phoneTrailingInset : 0)
            .overlay(alignment: .trailing) {
                phoneTrailingAccessory
            }
            .onChange(of: phone) { _, _ in
                onPhoneChange()
            }
    }

    @ViewBuilder
    private var phoneTrailingAccessory: some View {
        if resendSecondsRemaining > 0 {
            Text(LoginCopy.resendCountdownCompact(seconds: resendSecondsRemaining))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .accessibilityLabel(LoginCopy.resendCountdown(seconds: resendSecondsRemaining))
        } else if showsSendArrow {
            sendOTPArrowButton
        }
    }

    private var phoneTrailingInset: CGFloat {
        if resendSecondsRemaining > 0 { return 40 }
        return 32
    }

    private var sendOTPArrowButton: some View {
        Button {
            focusedField = nil
            Task { await onSendOTP() }
        } label: {
            if isSendingOTP {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: otpSent ? "arrow.clockwise.circle.fill" : "arrow.forward.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .buttonStyle(.borderless)
        .disabled(isSendingOTP || isInteractionDisabled)
        .accessibilityLabel(
            otpSent ? LoginCopy.resendVerificationCode : sendCodeAccessibilityLabel
        )
        .accessibilityAddTraits(.isButton)
        // REASONING: Overlay keeps Form row height native; expand tap without layout growth.
        .padding(10)
        .contentShape(Rectangle())
    }

    private var verificationCodeRow: some View {
        TextField(verificationCodePlaceholder, text: $verificationCode)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .authTextFieldChrome(focus: $focusedField, field: .verificationCode)
            .onChange(of: verificationCode) { _, _ in
                onVerificationCodeChange()
            }
    }
}

extension View {
    func authTextFieldChrome<Field: Hashable>(
        focus: FocusState<Field?>.Binding,
        field: Field
    ) -> some View {
        textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused(focus, equals: field)
    }
}
