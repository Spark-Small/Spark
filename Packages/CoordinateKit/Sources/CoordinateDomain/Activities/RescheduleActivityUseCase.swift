//
//  RescheduleActivityUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct RescheduleActivityUseCase: Sendable {
    public init() {}

    public func execute(
        activityID: UUID,
        date: Date,
        activities: inout [Activity],
        hostName: String,
        hostUserID: UUID?,
        now: Date = .now
    ) -> Result<Void, RescheduleActivityFailure> {
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
        guard date > now else {
            return .failure(.dateNotInFuture)
        }

        activities[index].date = date
        return .success(())
    }
}
