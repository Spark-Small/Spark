// Module: Spark App — Shared WeChat / Alipay / phone SDK configuration.

import Foundation
import SparkAuth
import SparkPayments

enum CNVendorConfiguration {
    private static func string(forKey key: String) -> String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static var weChatAppID: String? { string(forKey: "SparkWeChatAppID") }
    static var weChatUniversalLink: String? { string(forKey: "SparkWeChatUniversalLink") }
    static var alipayAppID: String? { string(forKey: "SparkAlipayAppID") }
    static var aliyunPhoneSDKKey: String? { string(forKey: "SparkAliyunPhoneAuthSDKKey") }
    static var tencentPhoneAppID: String? { string(forKey: "SparkTencentPhoneAuthAppID") }

    static var phoneOneTapPrimary: PhoneOneTapProvider {
        let raw = string(forKey: "SparkPhoneOneTapPrimary")?.lowercased()
        return raw == "tencent" ? .tencent : .aliyun
    }

    /// When true, Live builds without vendor SDK binaries use staging magic tokens (QA only).
    static var allowsStagingBridge: Bool {
        #if SPARK_CN_AUTH_STAGING_BRIDGE
        return true
        #else
        return string(forKey: "SparkCNAuthStagingBridge") == "1"
        #endif
    }

    static var isWeChatConfigured: Bool { weChatAppID != nil }
    static var isAlipayConfigured: Bool { alipayAppID != nil }
    static var isAliyunPhoneConfigured: Bool { aliyunPhoneSDKKey != nil }
    static var isTencentPhoneConfigured: Bool { tencentPhoneAppID != nil }

    static var isAnyCNProviderConfigured: Bool {
        isWeChatConfigured || isAlipayConfigured || isAliyunPhoneConfigured || isTencentPhoneConfigured
    }
}
