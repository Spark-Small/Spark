// Module: Spark App — SwiftUI environment for community posts repository.

import SparkCommunity
import SwiftUI

public struct CommunityPostsRepositoryBox: @unchecked Sendable {
    public let repository: any CommunityPostsRepository

    public init(_ repository: any CommunityPostsRepository) {
        self.repository = repository
    }
}

private struct CommunityPostsRepositoryEnvironmentKey: EnvironmentKey {
    static let defaultValue = CommunityPostsRepositoryBox(MockCommunityPostsRepository())
}

public extension EnvironmentValues {
    var communityPostsRepositoryBox: CommunityPostsRepositoryBox {
        get { self[CommunityPostsRepositoryEnvironmentKey.self] }
        set { self[CommunityPostsRepositoryEnvironmentKey.self] = newValue }
    }
}
