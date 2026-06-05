// Module: SparkMessages — Lightweight user profile for inbox UI.

import Foundation

public struct InboxUserProfile: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let avatarURL: URL?
    public let firstName: String

    public init(
        id: String,
        displayName: String,
        avatarURL: URL? = nil,
        firstName: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.firstName = firstName ?? displayName.split(separator: " ").first.map(String.init) ?? displayName
    }
}
