import Foundation

public struct Activity: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var title: String
    public var category: ActivityCategory
    public var location: String
    public var date: Date
    public var capacity: Int
    public var joined: Int
    public var hostName: String
    public var summary: String
    public var fee: String
    public var tags: [String]
    /// 距用户大致距离（km），示例数据；正式版可接定位
    public var distanceKM: Double
    /// 发起时上传的本地封面文件名
    public var localCoverName: String?
    /// 真实报名参与者；为空时详情页用种子展示兜底
    public var participantNames: [String]
    public var latitude: Double?
    public var longitude: Double?
    /// 关联兴趣圈子（详情可进圈子群）
    public var relatedCircleID: UUID?

    public init(
        id: UUID,
        title: String,
        category: ActivityCategory,
        location: String,
        date: Date,
        capacity: Int,
        joined: Int,
        hostName: String,
        summary: String,
        fee: String,
        tags: [String],
        distanceKM: Double = 2.0,
        localCoverName: String? = nil,
        participantNames: [String] = [],
        latitude: Double? = nil,
        longitude: Double? = nil,
        relatedCircleID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.location = location
        self.date = date
        self.capacity = capacity
        self.joined = joined
        self.hostName = hostName
        self.summary = summary
        self.fee = fee
        self.tags = tags
        self.distanceKM = distanceKM
        self.localCoverName = localCoverName
        self.participantNames = participantNames
        self.latitude = latitude
        self.longitude = longitude
        self.relatedCircleID = relatedCircleID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(ActivityCategory.self, forKey: .category)
        location = try container.decode(String.self, forKey: .location)
        date = try container.decode(Date.self, forKey: .date)
        capacity = try container.decode(Int.self, forKey: .capacity)
        joined = try container.decode(Int.self, forKey: .joined)
        hostName = try container.decode(String.self, forKey: .hostName)
        summary = try container.decode(String.self, forKey: .summary)
        fee = try container.decode(String.self, forKey: .fee)
        tags = try container.decode([String].self, forKey: .tags)
        distanceKM = try container.decodeIfPresent(Double.self, forKey: .distanceKM) ?? 2.0
        localCoverName = try container.decodeIfPresent(String.self, forKey: .localCoverName)
        participantNames = try container.decodeIfPresent([String].self, forKey: .participantNames) ?? []
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        relatedCircleID = try container.decodeIfPresent(UUID.self, forKey: .relatedCircleID)
    }

    public var remainingSpots: Int { max(capacity - joined, 0) }
    public var isAlmostFull: Bool { remainingSpots <= 3 && !isFull }
    public var isFull: Bool { remainingSpots == 0 }

    public var fillProgress: Double {
        guard capacity > 0 else { return 0 }
        return min(Double(joined) / Double(capacity), 1)
    }

    public var isFree: Bool {
        fee.contains("免费") || fee.caseInsensitiveCompare("免费") == .orderedSame
    }

    /// 需走 App 内支付；店内 AA / 自费点单等只展示费用，不拉起支付
    public var requiresInAppPayment: Bool {
        guard !isFree else { return false }
        let trimmed = fee.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return !Self.isVenueSelfPayFee(trimmed)
    }

    /// 店内 AA / 自费点单 / 现场结算（不入 App 支付）
    public static func isVenueSelfPayFee(_ fee: String) -> Bool {
        fee.contains("自费")
            || fee.contains("AA")
            || fee.contains("店内")
            || fee.contains("现场")
    }

    public var isPast: Bool { date < .now }

    public var hasAvailableSpots: Bool { !isFull }

    /// 精确距离文案（假定已有实测或可展示的 km）
    public var distanceText: String {
        if distanceKM < 1 {
            return String(format: "%.0f 米", distanceKM * 1000)
        }
        return String(format: "%.1f 公里", distanceKM)
    }

    /// 浏览卡用：无用户定位时不展示种子公里，改用行政区片段
    public var districtLabel: String {
        let parts = location.split(separator: "·", maxSplits: 1, omittingEmptySubsequences: true)
        if let first = parts.first {
            return first.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return location
    }

    public func distanceLabel(hasUserLocation: Bool) -> String {
        hasUserLocation ? distanceText : districtLabel
    }

    public var coverSeed: Int { id.stableSeed }

    /// 封面 SF Symbol：按 seed 在类别内轮换，避免同品类同一图标
    public var coverSymbol: String {
        category.coverSymbol(forSeed: coverSeed)
    }
}
