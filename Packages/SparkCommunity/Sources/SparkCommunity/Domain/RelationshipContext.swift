// Module: SparkCommunity — Viewer relationship hints for trust context.

import Foundation

public enum RelationshipContext: Sendable, Equatable, Hashable {
    case sharedActivity(String)
    case attendedLinkedActivity
    case matched
    case liked
    case none
}

public struct SharedActivityContext: Sendable, Equatable, Hashable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct LinkedActivityContext: Sendable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let scheduleLine: String?
    public let coverURL: URL?
    public let attendeeSummary: String?

    public init(
        id: String,
        name: String,
        scheduleLine: String? = nil,
        coverURL: URL? = nil,
        attendeeSummary: String? = nil
    ) {
        self.id = id
        self.name = name
        self.scheduleLine = scheduleLine
        self.coverURL = coverURL
        self.attendeeSummary = attendeeSummary
    }
}
