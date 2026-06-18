// Module: SparkAuth — CN mobile number validation (11 digits, 1-prefix).

import Foundation

enum PhoneNumberValidator {
    static func normalizedDigits(_ raw: String) -> String {
        raw.filter(\.isNumber)
    }

    static func isValidCNMobile(_ raw: String) -> Bool {
        let digits = normalizedDigits(raw)
        guard digits.count == 11, digits.first == "1" else { return false }
        return digits.allSatisfy(\.isNumber)
    }
}
