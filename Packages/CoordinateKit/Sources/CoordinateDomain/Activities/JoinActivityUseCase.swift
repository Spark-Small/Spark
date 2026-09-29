//
//  JoinActivityUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct JoinActivityUseCase: Sendable {
    public init() {}

    public func execute(
        activityID: UUID,
        activities: inout [Activity],
        joinedIDs: inout Set<UUID>,
        waitlistIDs: inout Set<UUID>,
        waitlistSpotNotifiedIDs: inout Set<UUID>,
        currentUserName: String,
        now: Date = .now
    ) -> Result<Void, JoinActivityFailure> {
        guard let index = activities.firstIndex(where: { $0.id == activityID }) else {
            return .failure(.activityNotFound)
        }
        if joinedIDs.contains(activityID) {
            return .failure(.alreadyJoined)
        }
        let activity = activities[index]
        if activity.isFull {
            return .failure(.alreadyFull)
        }
        if activity.isLifecycleEnded(at: now) {
            return .failure(.lifecycleEnded)
        }

        joinedIDs.insert(activityID)
        waitlistIDs.remove(activityID)
        waitlistSpotNotifiedIDs.remove(activityID)
        activities[index].joined = min(activities[index].joined + 1, activities[index].capacity)
        if !activities[index].participantNames.contains(currentUserName) {
            activities[index].participantNames.append(currentUserName)
        }
        return .success(())
    }
}
