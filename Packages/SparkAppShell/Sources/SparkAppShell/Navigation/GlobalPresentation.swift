// Module: SparkAppShell — App-wide sheet and full-screen cover payloads.

import Foundation
import SparkPayments

public enum GlobalPresentation: Identifiable, Equatable, Sendable {
    case authRequired
    case info(title: String, message: String)
    case paywall(placement: PaywallPlacement)

    public var id: String {
        switch self {
        case .authRequired:
            "authRequired"
        case let .info(title, message):
            "info-\(title)-\(message)"
        case let .paywall(placement):
            "paywall-\(placement.rawValue)"
        }
    }

    public var isFullScreen: Bool {
        switch self {
        case .authRequired:
            false
        case .info, .paywall:
            true
        }
    }
}
