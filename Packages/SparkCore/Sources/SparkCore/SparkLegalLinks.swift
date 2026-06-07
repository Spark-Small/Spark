// Module: SparkCore — Legal URLs and compliance copy (App Store / PIPL).

import Foundation

public enum SparkLegalLinks: Sendable {
    private static let privacyKey = "SPARKLegalPrivacyURL"
    private static let termsKey = "SPARKLegalTermsURL"
    private static let icpKey = "SPARKICPRecordNumber"

    public static var privacyPolicyURL: URL {
        url(forInfoKey: privacyKey, default: "https://spark.app/legal/privacy")
    }

    public static var termsOfServiceURL: URL {
        url(forInfoKey: termsKey, default: "https://spark.app/legal/terms")
    }

    /// Display on About screen for CN App Store (replace via Info.plist before release).
    public static var icpRecordNumber: String {
        if let value = Bundle.main.object(forInfoDictionaryKey: icpKey) as? String,
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }
        return String(
            localized: "legal.icp.placeholder",
            defaultValue: "ICP 备案号待更新",
            comment: "ICP record placeholder until legal provides number"
        )
    }

    private static func url(forInfoKey key: String, default defaultString: String) -> URL {
        if let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           let url = URL(string: raw),
           !raw.isEmpty {
            return url
        }
        guard let url = URL(string: defaultString) else {
            preconditionFailure("Invalid default legal URL: \(defaultString)")
        }
        return url
    }
}
