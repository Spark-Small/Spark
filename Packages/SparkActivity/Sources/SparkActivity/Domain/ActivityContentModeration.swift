// Module: SparkActivity — Client-side publish guard (Phase 23; server is source of truth).

import Foundation
import SparkCore

enum ActivityContentModeration {
    static func validatePublishableText(_ text: String) throws {
        if UGCModeration.firstViolation(in: text) != nil {
            throw ActivityError.contentRejected
        }
    }

    static func validateDraft(_ draft: CreateActivityDraft) throws {
        try validatePublishableText(draft.title)
        try validatePublishableText(draft.description)
        try validatePublishableText(draft.locationName)
    }
}
