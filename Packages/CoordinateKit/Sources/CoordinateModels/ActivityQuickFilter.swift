import Foundation

/// 活动发现快捷筛选（今天 / 明天 + 通用条件）
public enum ActivityQuickFilter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case weekend = "本周末"
    case today = "今天"
    case tomorrow = "明天"
    case nearby = "附近"
    case free = "免费"
    case available = "有空位"

    public var id: String { rawValue }

    public var isTimeFilter: Bool {
        self == .weekend || self == .today || self == .tomorrow
    }
}
