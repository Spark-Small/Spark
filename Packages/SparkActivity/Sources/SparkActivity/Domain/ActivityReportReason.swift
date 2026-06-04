// Module: SparkActivity — Registrant safety report reasons.

import Foundation

public enum ActivityReportReason: String, Sendable, CaseIterable, Identifiable {
    case spam
    case inappropriate
    case safety
    case other

    public var id: String { rawValue }

    public var localizedLabel: String {
        switch self {
        case .spam:
            String(localized: "activity.report.spam", defaultValue: "垃圾或广告", comment: "Report reason")
        case .inappropriate:
            String(localized: "activity.report.inappropriate", defaultValue: "不当内容", comment: "Report reason")
        case .safety:
            String(localized: "activity.report.safety", defaultValue: "安全顾虑", comment: "Report reason")
        case .other:
            String(localized: "activity.report.other", defaultValue: "其他", comment: "Report reason")
        }
    }
}
