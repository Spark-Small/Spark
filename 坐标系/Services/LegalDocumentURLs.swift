//
//  LegalDocumentURLs.swift
//  坐标系
//
//  用户协议 / 隐私政策托管 HTTPS 地址（App Store Review 5.1.1）。
//  App 内长文仅作无网兜底；提审前须确认公网可打开。
//

import Foundation

enum LegalDocumentURLs {
    private static let privacyOverrideKey = "legal.privacyURLOverride"
    private static let agreementOverrideKey = "legal.agreementURLOverride"

    /// 正式托管隐私政策。DEBUG 可用 UserDefaults 覆盖。
    static var privacy: URL {
        #if DEBUG
        if let override = overriddenURL(forKey: privacyOverrideKey) {
            return override
        }
        #endif
        return URL(string: "https://www.zuobiaoxi.com/privacy")!
    }

    /// 正式托管用户协议。DEBUG 可用 UserDefaults 覆盖。
    static var agreement: URL {
        #if DEBUG
        if let override = overriddenURL(forKey: agreementOverrideKey) {
            return override
        }
        #endif
        return URL(string: "https://www.zuobiaoxi.com/terms")!
    }

    static func url(for document: LegalHostedDocument) -> URL {
        switch document {
        case .privacy: privacy
        case .agreement: agreement
        }
    }

    #if DEBUG
    private static func overriddenURL(forKey key: String) -> URL? {
        guard let raw = UserDefaults.standard.string(forKey: key)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http"
        else { return nil }
        return url
    }
    #endif
}

enum LegalHostedDocument: String, Identifiable {
    case agreement
    case privacy

    var id: String { rawValue }

    var hostedURL: URL { LegalDocumentURLs.url(for: self) }

    var offlineTitle: String {
        switch self {
        case .agreement: "用户协议（离线）"
        case .privacy: "隐私政策（离线）"
        }
    }
}
