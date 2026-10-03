//
//  CancelActivityUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct CancelActivityUseCase: Sendable {
    public init() {}

    public func execute(
        activityID: UUID,
        activities: inout [Activity],
        joinedIDs: inout Set<UUID>,
        favoriteIDs: inout Set<UUID>,
        waitlistIDs: inout Set<UUID>,
        hostName: String,
        hostUserID: UUID?
    ) -> Result<CancelActivityResult, CancelActivityFailure> {
        guard let index = activities.firstIndex(where: { $0.id == activityID }) else {
            return .failure(.activityNotFound)
        }
        guard ActivityHostAuthorization.isHost(
            activities[index],
            hostName: hostName,
            hostUserID: hostUserID
        ) else {
            return .failure(.notHost)
        }

        let coverName = activities[index].localCoverName
        joinedIDs.remove(activityID)
        favoriteIDs.remove(activityID)
        waitlistIDs.remove(activityID)
        activities.remove(at: index)
        return .success(CancelActivityResult(coverName: coverName))
    }
}
