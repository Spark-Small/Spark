// Module: SparkAuth — Third-party login providers shown on LoginView.

import Foundation

enum LoginThirdPartySignInKind: String, CaseIterable, Sendable {
    case apple
    case alipay
    case weChat

    /// Left-to-right order on `LoginThirdPartySignInBar` (TAB_SCREENS L3).
    static let loginBarDisplayOrder: [LoginThirdPartySignInKind] = [.apple, .alipay, .weChat]
}
