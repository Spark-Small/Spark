// Module: SparkActivity — Local custom + favorited create templates.

import Foundation
import Observation
import os
import SparkCore

@MainActor
@Observable
public final class ActivityCreateTemplateStore {
    private static let storageKey = "spark.activity.createTemplates"
    private static let logger = Logger(subsystem: SparkLog.subsystem, category: "ActivityCreateTemplate")

    public private(set) var savedTemplates: [ActivityCreateSavedTemplate]

    public init(savedTemplates: [ActivityCreateSavedTemplate]? = nil) {
        if let savedTemplates {
            self.savedTemplates = savedTemplates
        } else if let data = UserDefaults.standard.data(forKey: Self.storageKey),
                  let decoded = try? JSONDecoder().decode([ActivityCreateSavedTemplate].self, from: data) {
            self.savedTemplates = decoded
        } else {
            self.savedTemplates = []
        }
    }

    public var customTemplates: [ActivityCreateSavedTemplate] {
        savedTemplates.filter { $0.source == .custom }
    }

    public var favoritedTemplates: [ActivityCreateSavedTemplate] {
        savedTemplates.filter { $0.source == .favorited }
    }

    public func isFavorited(activityID: String) -> Bool {
        savedTemplates.contains { $0.sourceActivityID == activityID }
    }

    @discardableResult
    public func saveCustom(from draft: CreateActivityDraft, name: String) -> ActivityCreateSavedTemplate? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedTitle.isEmpty else { return nil }

        let template = ActivityCreateSavedTemplate.from(draft: draft, name: trimmedName)
        savedTemplates.removeAll { $0.source == .custom && $0.name == trimmedName }
        savedTemplates.insert(template, at: 0)
        persist()
        return template
    }

    @discardableResult
    public func favorite(activity: ActivityDetail) -> ActivityCreateSavedTemplate {
        if let index = savedTemplates.firstIndex(where: { $0.sourceActivityID == activity.id }) {
            return savedTemplates[index]
        }
        let template = ActivityCreateSavedTemplate.from(activity: activity)
        savedTemplates.insert(template, at: 0)
        persist()
        return template
    }

    public func remove(id: String) {
        savedTemplates.removeAll { $0.id == id }
        persist()
    }

    public func unfavorite(activityID: String) {
        savedTemplates.removeAll { $0.sourceActivityID == activityID }
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(savedTemplates)
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        } catch {
            Self.logger.error("Failed to persist create templates: \(error.localizedDescription, privacy: .public)")
        }
    }
}
