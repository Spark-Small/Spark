// Module: SparkCore — Application-wide typed errors.

import Foundation

/// Unified error surface for networking, auth, persistence, and features.
public enum AppError: Error, Sendable, Equatable {
    case networkUnavailable
    case unauthorized
    case decodingFailed
    case server(statusCode: Int, message: String?)
    case unknown(message: String)
}

extension AppError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            String(localized: "error.network.unavailable", defaultValue: "网络不可用", comment: "Network error")
        case .unauthorized:
            String(localized: "error.unauthorized", defaultValue: "登录已过期", comment: "Auth error")
        case .decodingFailed:
            String(localized: "error.decoding", defaultValue: "数据解析失败", comment: "Decode error")
        case let .server(statusCode, message):
            message ?? String(
                localized: "error.server.format",
                defaultValue: "服务器错误（\(statusCode)）",
                comment: "Server error with status code"
            )
        case let .unknown(message):
            message
        }
    }
}
