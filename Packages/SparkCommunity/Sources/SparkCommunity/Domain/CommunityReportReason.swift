// Module: SparkCommunity — Report reason wire values (API_CONTRACT MODULE-E.4).

import Foundation

public enum CommunityReportReason: String, CaseIterable, Identifiable, Sendable {
    case spam
    case harassment
    case other

    public var id: String { rawValue }

    public var wireValue: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .spam:
            String(localized: "community.report.reason.spam", defaultValue: "垃圾信息", comment: "Report spam")
        case .harassment:
            String(
                localized: "community.report.reason.harassment",
                defaultValue: "骚扰或不安全",
                comment: "Report harassment"
            )
        case .other:
            String(localized: "community.report.reason.other", defaultValue: "其他", comment: "Report other")
        }
    }
}
