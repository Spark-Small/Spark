//
//  PromoteFromWaitlistUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct PromoteFromWaitlistUseCase: Sendable {
    private let joinActivity: JoinActivityUseCase

    public init(joinActivity: JoinActivityUseCase = JoinActivityUseCase()) {
        self.joinActivity = joinActivity
    }

    public func execute(
        activityID: UUID,
        activities: inout [Activity],
        joinedIDs: inout Set<UUID>,
        waitlistIDs: inout Set<UUID>,
        waitlistSpotNotifiedIDs: inout Set<UUID>,
        currentUserName: String,
        hasPaid: Bool,
        now: Date = .now
    ) -> Result<Void, PromoteFromWaitlistFailure> {
        guard waitlistIDs.contains(activityID) else {
            return .failure(.notOnWaitlist)
        }
        guard let activity = activities.first(where: { $0.id == activityID }),
              activity.isJoinable(now: now)
        else {
            return .failure(.notJoinable)
        }
        if activity.requiresInAppPayment, !hasPaid {
            return .failure(.paymentRequired)
        }

        switch joinActivity.execute(
            activityID: activityID,
            activities: &activities,
            joinedIDs: &joinedIDs,
            waitlistIDs: &waitlistIDs,
            waitlistSpotNotifiedIDs: &waitlistSpotNotifiedIDs,
            currentUserName: currentUserName,
            now: now
        ) {
        case .success:
            return .success(())
        case .failure(let failure):
            return .failure(.joinFailed(failure))
        }
    }
}
