// Module: SparkAuth — OAuth providers for CN third-party sign-in.

import Foundation

/// WeChat / Alipay authorization providers (MODULE-H SDK wires into `ThirdPartySignInCoordinator`).
public enum AuthThirdPartyLoginProvider: String, Sendable, Equatable, CaseIterable {
    case weChat = "wechat"
    case alipay
}
