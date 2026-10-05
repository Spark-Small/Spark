import Foundation

/// 个人资料 / 对外展示用性别（与搭子目录「男 / 女」文案对齐）。
public enum ProfileGender: String, Codable, CaseIterable, Sendable, Hashable {
    case male = "男"
    case female = "女"
}
