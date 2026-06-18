// Module: SparkActivity — Navigation payload for detail context.

import Foundation

/// Carries browse vs inbox context into `NavigationStack` / split detail.
public struct ActivityDetailRoute: Hashable, Sendable, Equatable {
    public let activityID: String
    public let context: ActivityDetailContext

    public init(activityID: String, context: ActivityDetailContext) {
        self.activityID = activityID
        self.context = context
    }
}
