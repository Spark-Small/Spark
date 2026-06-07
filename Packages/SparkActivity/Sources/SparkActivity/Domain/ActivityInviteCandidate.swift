// Module: SparkActivity — In-app invite candidate from messages inbox.

import Foundation

public struct ActivityInviteCandidate: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let avatarURL: URL?

    public init(id: String, displayName: String, avatarURL: URL? = nil) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
    }
}
