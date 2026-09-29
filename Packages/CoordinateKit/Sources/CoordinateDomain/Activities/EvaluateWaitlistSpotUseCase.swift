//
//  EvaluateWaitlistSpotUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct EvaluateWaitlistSpotUseCase: Sendable {
    public init() {}

    public func execute(
        activityID: UUID,
        activity: Activity,
        isOnWaitlist: Bool,
        waitlistSpotNotifiedIDs: inout Set<UUID>,
        now: Date = .now
    ) -> WaitlistSpotEffect {
        guard isOnWaitlist else { return .none }

        if activity.isFull || activity.isLifecycleEnded(at: now) {
            guard waitlistSpotNotifiedIDs.remove(activityID) != nil else { return .none }
            return .revoke(activityID: activityID)
        }

        guard !waitlistSpotNotifiedIDs.contains(activityID) else { return .none }
        waitlistSpotNotifiedIDs.insert(activityID)
        return .notify(activityID: activityID, title: activity.title)
    }
}
