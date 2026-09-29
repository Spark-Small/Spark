//
//  ToggleWaitlistUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct ToggleWaitlistUseCase: Sendable {
    public init() {}

    public func execute(
        activityID: UUID,
        activities: [Activity],
        joinedIDs: Set<UUID>,
        waitlistIDs: inout Set<UUID>,
        waitlistSpotNotifiedIDs: inout Set<UUID>,
        now: Date = .now
    ) -> ToggleWaitlistResult {
        guard let activity = activities.first(where: { $0.id == activityID }) else {
            return .activityNotFound
        }
        guard activity.isFull,
              !joinedIDs.contains(activityID),
              !activity.isLifecycleEnded(at: now)
        else {
            return .unnecessary
        }

        if waitlistIDs.contains(activityID) {
            waitlistIDs.remove(activityID)
            waitlistSpotNotifiedIDs.remove(activityID)
            return .left
        }

        waitlistIDs.insert(activityID)
        return .joined
    }
}
