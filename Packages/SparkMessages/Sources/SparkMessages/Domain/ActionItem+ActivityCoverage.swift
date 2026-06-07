// Module: SparkMessages — Dedup action cards against activity feed rows.

import Foundation

extension ActionItem {
    /// Activity id represented by this inbox request card.
    public var coveredActivityID: String? {
        switch kind {
        case .activityInvite(let invite):
            invite.activity.id
        case .activityChanged(let change):
            change.activity.id
        case .waitlistPromoted(let activity):
            activity.id
        }
    }
}

extension [ActionItem] {
    public var coveredActivityIDs: Set<String> {
        Set(compactMap(\.coveredActivityID))
    }
}
