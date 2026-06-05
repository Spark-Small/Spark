// Module: SparkCommunity — Activity linked to a community (summary only).

import Foundation

public struct CommunityLinkedActivity: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let title: String
    public let scheduleLine: String

    public init(id: String, title: String, scheduleLine: String) {
        self.id = id
        self.title = title
        self.scheduleLine = scheduleLine
    }
}
