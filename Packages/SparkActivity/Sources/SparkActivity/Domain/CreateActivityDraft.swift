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
        validationError == nil
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

    /// Pre-fills a lightweight 3-person coffee meetup after a mutual match (Nexus W3).
    public static func matchCoffee(peerName: String) -> CreateActivityDraft {
        let titleFormat = String(
            localized: "activity.create.matchCoffee.title.format",
            defaultValue: "和 %@ 的咖啡小局",
            comment: "Match coffee title; %@ peer name"
        )
        let title = String(format: titleFormat, locale: .current, peerName)
        let description = String(
            localized: "activity.create.matchCoffee.description",
            defaultValue: "配对后的轻量见面局，最多 3 人，选个方便的咖啡馆聊聊。",
            comment: "Match coffee description"
        )
        return CreateActivityDraft(
            title: title,
            description: description,
            locationName: "",
            startsAt: Date().addingTimeInterval(172_800),
            capacity: 3
        )
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
