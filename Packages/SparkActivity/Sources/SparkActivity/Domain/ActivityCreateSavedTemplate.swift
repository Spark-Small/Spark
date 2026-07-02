// Module: SparkActivity — User-saved or favorited create-activity templates.

import Foundation

public struct ActivityCreateSavedTemplate: Codable, Identifiable, Hashable, Sendable {
    public enum Source: String, Codable, Sendable {
        case custom
        case favorited
    }

    public let id: String
    public var name: String
    public var title: String
    public var description: String
    public var category: String
    public var capacity: Int
    public var systemImage: String
    public var source: Source
    public var sourceActivityID: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        title: String,
        description: String = "",
        category: String = "",
        capacity: Int = CreateActivityDraft.defaultCapacity,
        systemImage: String = "sparkles",
        source: Source,
        sourceActivityID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.description = description
        self.category = category
        self.capacity = capacity
        self.systemImage = systemImage
        self.source = source
        self.sourceActivityID = sourceActivityID
    }

    public static func from(draft: CreateActivityDraft, name: String) -> ActivityCreateSavedTemplate {
        ActivityCreateSavedTemplate(
            name: name,
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category.trimmingCharacters(in: .whitespacesAndNewlines),
            capacity: draft.capacity ?? CreateActivityDraft.defaultCapacity,
            systemImage: "square.and.pencil",
            source: .custom
        )
    }

    public static func from(activity: ActivityDetail) -> ActivityCreateSavedTemplate {
        let name = activity.title.trimmingCharacters(in: .whitespacesAndNewlines)
        return ActivityCreateSavedTemplate(
            name: name.isEmpty ? activity.category : name,
            title: activity.title,
            description: activity.description,
            category: activity.category,
            capacity: activity.capacity ?? CreateActivityDraft.defaultCapacity,
            systemImage: "star.fill",
            source: .favorited,
            sourceActivityID: activity.id
        )
    }

    public func apply(to draft: inout CreateActivityDraft) {
        draft.title = title
        draft.description = description
        draft.category = category
        draft.capacity = capacity
    }
}
