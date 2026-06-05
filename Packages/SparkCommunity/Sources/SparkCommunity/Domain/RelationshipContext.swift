// Module: SparkCommunity — Viewer relationship hints for trust context.

import Foundation

public enum RelationshipContext: Sendable, Equatable, Hashable {
    case sharedActivity(String)
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

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
