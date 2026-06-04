// Module: Spark App — SwiftUI environment for activity feed repository.

import SparkActivity
import SwiftUI

/// Type-erased `ActivityFeedRepository` for `@Environment` (existential `EnvironmentKey`).
public struct ActivityFeedRepositoryBox: @unchecked Sendable {
    // REASONING: Environment values must be Sendable; repository existential is only used on MainActor.
    public let repository: any ActivityFeedRepository

    public init(_ repository: any ActivityFeedRepository) {
        self.repository = repository
    }
}

private struct ActivityFeedRepositoryEnvironmentKey: EnvironmentKey {
    static let defaultValue = ActivityFeedRepositoryBox(MockActivityFeedRepository())
}

public extension EnvironmentValues {
    var activityFeedRepositoryBox: ActivityFeedRepositoryBox {
        get { self[ActivityFeedRepositoryEnvironmentKey.self] }
        set { self[ActivityFeedRepositoryEnvironmentKey.self] = newValue }
    }
}
