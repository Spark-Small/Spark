// Module: SparkLikes — Feature errors.

import Foundation
import SparkCore

public enum LikesError: LocalizedError, Sendable, Equatable {
    case underlying(AppError)
    case alreadyConnected
    case rewindUnavailable
    case sparkChargesExhausted

    public var errorDescription: String? {
        switch self {
        case .underlying(let error):
            error.localizedDescription
        case .alreadyConnected:
            String(
                localized: "likes.error.alreadyConnected",
                defaultValue: "你们已经建立联系了",
                comment: "Already connected"
            )
        case .rewindUnavailable:
            String(
                localized: "likes.error.rewindUnavailable",
                defaultValue: "今天无法撤回，或没有可撤回的人",
                comment: "Rewind unavailable"
            )
        case .sparkChargesExhausted:
            String(
                localized: "likes.error.sparkExhausted",
                defaultValue: "今日心动次数已用完",
                comment: "Spark charges exhausted"
            )
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .underlying(let error):
            Self.recovery(for: error)
        case .alreadyConnected:
            String(
                localized: "likes.error.alreadyConnected.recovery",
                defaultValue: "可以直接发消息",
                comment: "Already connected recovery"
            )
        case .rewindUnavailable:
            String(
                localized: "likes.error.rewindUnavailable.recovery",
                defaultValue: "明天再试，或继续浏览新的推荐",
                comment: "Rewind unavailable recovery"
            )
        case .sparkChargesExhausted:
            String(
                localized: "likes.error.sparkExhausted.recovery",
                defaultValue: "升级后可获得更多心动次数",
                comment: "Spark exhausted recovery"
            )
        }
    }

    private static func recovery(for error: AppError) -> String? {
        switch error {
        case .networkUnavailable:
            String(
                localized: "likes.error.network.recovery",
                defaultValue: "检查网络连接后重试",
                comment: "Network recovery"
            )
        case .unauthorized:
            String(
                localized: "likes.error.unauthorized.recovery",
                defaultValue: "请重新登录",
                comment: "Auth recovery"
            )
        case .decodingFailed, .server, .unknown:
            String(
                localized: "likes.error.generic.recovery",
                defaultValue: "下拉刷新或稍后再试",
                comment: "Generic recovery"
            )
        }
    }
}
