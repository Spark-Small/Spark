// Module: SparkActivity — Feature errors mapped from transport.

import Foundation
import SparkCore

public enum ActivityError: LocalizedError, Sendable, Equatable {
    case underlying(AppError)
    case activityFull
    case contentRejected
    case emptyInput
    case fieldTooLong(field: Field)
    case invalidCapacity

    public enum Field: String, Sendable {
        case title
        case description
        case location
    }

    public var errorDescription: String? {
        switch self {
        case let .underlying(appError):
            return appError.errorDescription
        case .activityFull:
            return String(
                localized: "activity.error.full",
                defaultValue: "名额已满，无法选择参加。",
                comment: "RSVP full"
            )
        case .contentRejected:
            return String(
                localized: "activity.error.contentRejected",
                defaultValue: "内容包含不允许的词语，请修改后再发布。",
                comment: "Content moderation"
            )
        case .emptyInput:
            return String(
                localized: "activity.error.emptyInput",
                defaultValue: "请填写内容后再继续。",
                comment: "Empty input"
            )
        case .invalidCapacity:
            return String(
                localized: "activity.error.invalidCapacity",
                defaultValue: "人数需在 2–99 人之间。",
                comment: "Invalid capacity"
            )
        case let .fieldTooLong(field):
            return fieldTooLongDefault(field)
        }
    }

    private func fieldTooLongDefault(_ field: Field) -> String {
        switch field {
        case .title:
            "活动名称过长，请缩短后再试。"
        case .description:
            "活动说明过长，请缩短后再试。"
        case .location:
            "地点过长，请缩短后再试。"
        }
    }
}
