// Module: SparkCommunity — Client-side UGC guard (ADR-0007; server is source of truth).

import Foundation
import SparkCore

enum CommunityContentModeration {
    static func validatePublishableText(_ text: String) throws {
        if UGCModeration.firstViolation(in: text) != nil {
            throw CommunityError.contentRejected
        }
    }

    static func validatePostDraft(_ draft: CreateCommunityPostDraft) throws {
        try validatePublishableText(draft.title)
        try validatePublishableText(draft.body)
    }

    static func validateReplyBody(_ body: String) throws {
        try validatePublishableText(body)
    }
}
