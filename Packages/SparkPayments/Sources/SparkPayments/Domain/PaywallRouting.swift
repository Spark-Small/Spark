// Module: SparkPayments — Paywall presentation contract for feature modules.

import Foundation

public enum PaywallPlacement: String, Sendable, CaseIterable {
    case activity
    case messages
    case community
    case settings
}

/// Features call this protocol; the app shell owns actual presentation (sheet / fullScreenCover).
@MainActor
public protocol PaywallRouting: AnyObject {
    func presentPaywall(placement: PaywallPlacement)
    func dismissPaywall()
}
