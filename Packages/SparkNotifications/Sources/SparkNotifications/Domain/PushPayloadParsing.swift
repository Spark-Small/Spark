// Module: SparkNotifications — Shared APNs userInfo parsing helpers.

import Foundation

enum PushPayloadParsing {
    static func stringValue(_ value: Any?) -> String? {
        guard let raw = value as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
