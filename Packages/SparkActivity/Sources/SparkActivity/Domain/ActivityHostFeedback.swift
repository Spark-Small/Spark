// Module: SparkActivity — Post-event host feedback (Phase 24).

import Foundation

public enum ActivityHostFeedback: String, Sendable, CaseIterable {
    case positive
    case negative

    public var localizedLabel: String {
        switch self {
        case .positive:
            String(localized: "activity.feedback.positive", defaultValue: "愿意再参加", comment: "Host feedback")
        case .negative:
            String(localized: "activity.feedback.negative", defaultValue: "体验一般", comment: "Host feedback")
        }
    }
}
