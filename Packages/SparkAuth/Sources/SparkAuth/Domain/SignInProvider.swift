// Module: SparkAuth — Active sign-in channel for precise loading UI.

import Foundation

/// Identifies which login provider is currently in flight (LoginView loading indicators).
public enum SignInProvider: Sendable, Equatable {
    case wechat
    case phoneOneTap
    case phoneOtp
    case alipay
    case apple
}
