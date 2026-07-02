// Module: SparkAuth — Mainland China mobile number validation.

import Foundation

enum PhoneNumberValidator {
    static let mobileDigitCount = 11
    static let verificationCodeLength = 6

    /// CN mobile: 11 digits starting with 1.
    static func isValidCNMobile(_ raw: String) -> Bool {
        let digits = normalizedDigits(raw)
        return digits.count == mobileDigitCount && digits.hasPrefix("1")
    }

    static func normalizedDigits(_ raw: String) -> String {
        raw.filter(\.isNumber)
    }

    static func clampedCNMobileInput(_ raw: String) -> String {
        String(normalizedDigits(raw).prefix(mobileDigitCount))
    }

    static func clampedVerificationCode(_ raw: String) -> String {
        String(normalizedDigits(raw).prefix(verificationCodeLength))
    }
}
