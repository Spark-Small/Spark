//
//  LeaveActivityUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct LeaveActivityUseCase: Sendable {
    public init() {}

    public func execute(
        activityID: UUID,
        activities: inout [Activity],
        joinedIDs: inout Set<UUID>,
        currentUserName: String
    ) -> Result<Void, LeaveActivityFailure> {
        guard let index = activities.firstIndex(where: { $0.id == activityID }) else {
            return .failure(.activityNotFound)
        }
        guard joinedIDs.contains(activityID) else {
            return .failure(.notJoined)
        }

        joinedIDs.remove(activityID)
        activities[index].joined = max(activities[index].joined - 1, 0)
        activities[index].participantNames.removeAll { $0 == currentUserName }
        return .success(())
    }
}
