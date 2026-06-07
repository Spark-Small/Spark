// Module: SparkMessages — Peer selectable for starting a new DM thread.

import Foundation

public struct MessagesChatCandidate: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let avatarURL: URL?
    public let isNewMatch: Bool

    public init(
        id: String,
        displayName: String,
        avatarURL: URL? = nil,
        isNewMatch: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.isNewMatch = isNewMatch
    }
}
