//
//  VerificationPhoto.swift
//  CoordinateModels
//
//  资料页认证照：1–2 张，作摄像头比对基准；可单独设是否对外展示。
//

import Foundation

public struct VerificationPhoto: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    /// Application Support 下本地文件名（与头像同走 CommunityPhotoStore）
    public var localName: String
    /// 关闭后仅用于核验，不出现在他人可见档案
    public var isPublic: Bool

    public init(
        id: UUID = UUID(),
        localName: String,
        isPublic: Bool = false
    ) {
        self.id = id
        self.localName = localName
        self.isPublic = isPublic
    }
}

public enum VerificationPhotoLimits {
    public static let minCount = 1
    public static let maxCount = 2

    public static func isReady(_ photos: [VerificationPhoto]) -> Bool {
        (minCount...maxCount).contains(photos.count)
    }

    /// 比对基准指纹：文件名集合变化则需重验（可见性变更不影响）。
    public static func baselineFingerprint(for photos: [VerificationPhoto]) -> String {
        photos.map(\.localName).sorted().joined(separator: "|")
    }
}
