// Module: SparkActivity — Where the user entered the detail screen.

import Foundation

/// Drives invite-friends CTA vs inbox list entry.
public enum ActivityDetailContext: Sendable, Equatable {
    /// Opened from Activity tab list.
    case inbox
    /// Universal link / search (path B entry without a dedicated tab).
    case externalEntry
    /// Opened from Activity tab discover browse list.
    case discover

    var integrationTelemetrySource: String {
        switch self {
        case .inbox: "inbox"
        case .externalEntry: "external"
        case .discover: "browse"
        }
    }
}
