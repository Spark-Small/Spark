// Module: SparkActivity — Client-side publish guard (Phase 23; server is source of truth).

import Foundation

enum ActivityContentModeration {
    private static let blockedSubstrings = ["违禁", "赌博", "色情"]

    static func validatePublishableText(_ text: String) throws {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return }
        for token in blockedSubstrings where normalized.contains(token) {
            throw ActivityError.contentRejected
        }
    }

    static func validateDraft(_ draft: CreateActivityDraft) throws {
        try validatePublishableText(draft.title)
        try validatePublishableText(draft.description)
        try validatePublishableText(draft.locationName)
    }
}
