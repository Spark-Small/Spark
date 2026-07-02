// Module: SparkActivity — Meetup-style related topic chips derived from activity metadata.

import Foundation

enum ActivityRelatedTopics {
    /// Topics shown in the detail "Related topics" section (category + curated synonyms).
    static func topics(for activity: ActivityDetail) -> [String] {
        var result: [String] = []
        let category = activity.category.trimmingCharacters(in: .whitespacesAndNewlines)
        if !category.isEmpty {
            result.append(category)
        }
        for synonym in synonyms(for: category) where !result.contains(synonym) {
            result.append(synonym)
        }
        return result
    }

    private static func synonyms(for category: String) -> [String] {
        let normalized = category.lowercased()
        switch normalized {
        case "活动", "event", "events":
            return [
                String(localized: "activity.topic.social", defaultValue: "社交", comment: "Related topic"),
                String(localized: "activity.topic.outdoor", defaultValue: "户外", comment: "Related topic")
            ]
        case "户外", "outdoor", "hiking":
            return [
                String(localized: "activity.topic.adventure", defaultValue: "探险", comment: "Related topic"),
                String(localized: "activity.topic.outdoor", defaultValue: "户外", comment: "Related topic")
            ]
        case "旅行", "travel", "tours":
            return [
                String(localized: "activity.topic.travel", defaultValue: "旅行", comment: "Related topic"),
                String(localized: "activity.topic.tours", defaultValue: "跟团游", comment: "Related topic")
            ]
        default:
            return []
        }
    }
}
