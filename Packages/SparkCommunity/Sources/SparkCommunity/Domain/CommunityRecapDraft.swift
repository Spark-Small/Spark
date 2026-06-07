// Module: SparkCommunity — User-authored post-event recap payload.

import Foundation

public struct CommunityRecapDraft: Sendable, Equatable {
    public static let maxBodyLength = 2_000

    public let activityID: String
    public let activityTitle: String
    public let scheduleLine: String
    public let body: String

    public init(activityID: String, activityTitle: String, scheduleLine: String, body: String) {
        self.activityID = activityID
        self.activityTitle = activityTitle
        self.scheduleLine = scheduleLine
        self.body = body
    }

    public var normalizedBody: String {
        body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var postTitle: String {
        let format = String(
            localized: "community.recap.postTitle.format",
            defaultValue: "「%@」复盘",
            comment: "Recap post title; %@ activity title"
        )
        return String(format: format, locale: .current, activityTitle)
    }

    public static func validate(_ draft: CommunityRecapDraft) throws {
        let body = draft.normalizedBody
        guard !body.isEmpty else {
            throw CommunityError.emptyInput
        }
        if body.count > maxBodyLength {
            throw CommunityError.fieldTooLong
        }
    }
}
