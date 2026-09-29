//
//  MediaModerationModels.swift
//  坐标系
//
//  内容安全请求 / 响应（Private Detector 风格 JSON API）。
//

import Foundation

struct MediaModerationRequest: Codable, Sendable {
    var imageBase64: String
    var context: String
    var youthMode: Bool
}

struct MediaModerationResponse: Codable, Sendable {
    /// 0…1，越高越像不雅内容
    var nsfwScore: Double
    var blocked: Bool
    var reason: String?
}

struct IdentityReverifyRequest: Codable, Sendable {
    var userKey: String
    var baselineFingerprint: String
    var localSimilarity: Double
    var featureDigest: String
    var youthMode: Bool
}

struct IdentityReverifyResponse: Codable, Sendable {
    var passed: Bool
    var remoteScore: Double
    var reason: String?
}
