//
//  UpdateActivityCapacityUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct UpdateActivityCapacityUseCase: Sendable {
    public init() {}

    public func execute(
        activityID: UUID,
        capacity: Int,
        activities: inout [Activity],
        hostName: String,
        hostUserID: UUID?
    ) -> Result<UpdateCapacityResult, UpdateCapacityFailure> {
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

        let floor = max(activities[index].joined, 2)
        let next = max(capacity, floor)
        guard activities[index].capacity != next else {
            return .failure(.unchanged)
        }

        let wasFull = activities[index].isFull
        activities[index].capacity = next
        return .success(
            UpdateCapacityResult(
                capacity: next,
                openedSpotFromFull: wasFull && !activities[index].isFull
            )
        )
    }
}
