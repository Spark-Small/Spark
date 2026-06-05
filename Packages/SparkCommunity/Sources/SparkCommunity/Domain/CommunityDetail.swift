// Module: SparkCommunity — Full community for detail screen.

import Foundation

public struct CommunityDetail: Identifiable, Sendable, Equatable, Hashable {
    public var id: String { summary.id }
    public let summary: CommunitySummary
    public var isJoined: Bool

    public init(summary: CommunitySummary, isJoined: Bool) {
        self.summary = summary
        self.isJoined = isJoined
    }
}
