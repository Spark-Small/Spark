// Module: SparkActivity — Host creates a new invitation.

import Foundation

public struct CreateActivityDraft: Sendable, Equatable {
    public static let maxTitleLength = 80
    public static let maxDescriptionLength = 2_000
    public static let maxLocationLength = 120

    public var title: String
    public var description: String
    public var locationName: String
    public var startsAt: Date
    public var capacity: Int?

    public init(
        title: String = "",
        description: String = "",
        locationName: String = "",
        startsAt: Date = Date().addingTimeInterval(86_400),
        capacity: Int? = 10
    ) {
        self.title = title
        self.description = description
        self.locationName = locationName
        self.startsAt = startsAt
        self.capacity = capacity
    }

    public var isValid: Bool {
        (try? Self.validate(self)) == nil
    }

    public var validationError: ActivityError? {
        do {
            try Self.validate(self)
            return nil
        } catch let error as ActivityError {
            return error
        } catch {
            return nil
        }
    }

    /// Pre-fills create form after an ended activity (path D → C).
    public init(hostAgainFrom activity: ActivityDetail) {
        title = activity.title
        description = activity.description
        locationName = activity.locationName
        startsAt = max(Date().addingTimeInterval(86_400), activity.startsAt.addingTimeInterval(604_800))
        capacity = activity.capacity
    }

    public static func validate(_ draft: CreateActivityDraft) throws {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let location = draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !description.isEmpty, !location.isEmpty else {
            throw ActivityError.emptyInput
        }
        if title.count > maxTitleLength { throw ActivityError.fieldTooLong(field: .title) }
        if description.count > maxDescriptionLength { throw ActivityError.fieldTooLong(field: .description) }
        if location.count > maxLocationLength { throw ActivityError.fieldTooLong(field: .location) }
        try ActivityContentModeration.validatePublishableText(title)
        try ActivityContentModeration.validatePublishableText(description)
        try ActivityContentModeration.validatePublishableText(location)
    }
}
