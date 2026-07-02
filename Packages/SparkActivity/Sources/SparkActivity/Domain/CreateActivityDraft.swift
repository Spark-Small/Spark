// Module: SparkActivity — Host creates a new invitation.

import Foundation

public struct CreateActivityDraft: Sendable, Equatable {
    public static let maxTitleLength = 80
    public static let maxDescriptionLength = 2_000
    public static let maxLocationLength = 120
    public static let defaultCapacity = 6
    public static let smallGroupCapacityPresets = [3, 6, 12]
    public static let minCapacity = 2
    public static let maxCapacity = 99

    public var title: String
    public var description: String
    public var locationName: String
    public var category: String
    public var startsAt: Date
    public var capacity: Int?
    public var coverURL: URL?
    public var coverPosterURL: URL?
    public var coverIsVideo: Bool

    public init(
        title: String = "",
        description: String = "",
        locationName: String = "",
        category: String = "",
        startsAt: Date = Date().addingTimeInterval(86_400),
        capacity: Int? = defaultCapacity,
        coverURL: URL? = nil,
        coverPosterURL: URL? = nil,
        coverIsVideo: Bool = false
    ) {
        self.title = title
        self.description = description
        self.locationName = locationName
        self.category = category
        self.startsAt = startsAt
        self.capacity = capacity
        self.coverURL = coverURL
        self.coverPosterURL = coverPosterURL
        self.coverIsVideo = coverIsVideo
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
        category = activity.category
        startsAt = max(Date().addingTimeInterval(86_400), activity.startsAt.addingTimeInterval(604_800))
        capacity = activity.capacity
        coverURL = activity.coverURL
        coverPosterURL = activity.coverPosterURL
        coverIsVideo = activity.coverIsVideo
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

    /// Publishes with a short fallback description when the host skips the optional field.
    public func normalizedForPublish() -> CreateActivityDraft {
        var copy = self
        let trimmedDescription = copy.description.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedDescription.isEmpty {
            copy.description = Self.fallbackDescription(title: copy.title)
        }
        return copy
    }

    public static func validate(_ draft: CreateActivityDraft) throws {
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = draft.description.trimmingCharacters(in: .whitespacesAndNewlines)
        let location = draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !location.isEmpty else {
            throw ActivityError.emptyInput
        }
        if title.count > maxTitleLength { throw ActivityError.fieldTooLong(field: .title) }
        if !description.isEmpty, description.count > maxDescriptionLength {
            throw ActivityError.fieldTooLong(field: .description)
        }
        if location.count > maxLocationLength { throw ActivityError.fieldTooLong(field: .location) }
        if let capacity = draft.capacity {
            guard capacity >= minCapacity, capacity <= maxCapacity else {
                throw ActivityError.invalidCapacity
            }
        }
        try ActivityContentModeration.validatePublishableText(title)
        if !description.isEmpty {
            try ActivityContentModeration.validatePublishableText(description)
        }
        try ActivityContentModeration.validatePublishableText(location)
    }

    private static func fallbackDescription(title: String) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return String(
                localized: "activity.create.description.fallback.generic",
                defaultValue: "主办稍后补充说明。",
                comment: "Generic fallback description"
            )
        }
        let format = String(
            localized: "activity.create.description.fallback.format",
            defaultValue: "一起参加「%@」——细节现场沟通。",
            comment: "Fallback description; %@ is title"
        )
        return String(format: format, locale: .current, trimmedTitle)
    }
}
