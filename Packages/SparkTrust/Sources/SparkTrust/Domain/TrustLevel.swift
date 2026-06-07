// Module: SparkTrust — Trust verification tiers.

import Foundation

public enum TrustLevel: String, CaseIterable, Sendable, Equatable, Identifiable {
    case phone
    case realName
    case liveness
    case career
    case activityRecord
    case socialEndorsement

    public var id: String { rawValue }

    public var pointValue: Int {
        switch self {
        case .phone: 10
        case .realName: 25
        case .liveness: 30
        case .career: 20
        case .activityRecord: 15
        case .socialEndorsement: 0
        }
    }

    public var localizedTitle: String {
        switch self {
        case .phone:
            String(localized: "trust.level.phone", defaultValue: "手机认证", comment: "Trust level")
        case .realName:
            String(localized: "trust.level.realName", defaultValue: "实名认证", comment: "Trust level")
        case .liveness:
            String(localized: "trust.level.liveness", defaultValue: "活体认证", comment: "Trust level")
        case .career:
            String(localized: "trust.level.career", defaultValue: "职业认证", comment: "Trust level")
        case .activityRecord:
            String(localized: "trust.level.activity", defaultValue: "活动记录", comment: "Trust level")
        case .socialEndorsement:
            String(localized: "trust.level.social", defaultValue: "社交背书", comment: "Trust level")
        }
    }

    /// MVP verification wizard covers L1–L3 only.
    public static let mvpLevels: [TrustLevel] = [.phone, .realName, .liveness]
}
