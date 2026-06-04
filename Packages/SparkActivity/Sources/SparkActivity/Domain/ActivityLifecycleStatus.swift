// Module: SparkActivity — Scheduled / cancelled / ended (registrant-facing).

import Foundation

/// Server-driven activity lifecycle (`lifecycle_status` in API).
public enum ActivityLifecycleStatus: String, Sendable, Equatable, CaseIterable {
    case scheduled
    case cancelled
    case ended

    public init?(wireValue: String) {
        let normalized = wireValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.init(rawValue: normalized)
    }

    public var localizedLabel: String {
        switch self {
        case .scheduled:
            String(localized: "activity.lifecycle.scheduled", defaultValue: "进行中", comment: "Lifecycle")
        case .cancelled:
            String(localized: "activity.lifecycle.cancelled", defaultValue: "已取消", comment: "Lifecycle")
        case .ended:
            String(localized: "activity.lifecycle.ended", defaultValue: "已结束", comment: "Lifecycle")
        }
    }

    /// Registrant cannot change RSVP when the event is no longer active.
    public var blocksRegistration: Bool {
        switch self {
        case .scheduled:
            false
        case .cancelled, .ended:
            true
        }
    }
}
