//
//  ToggleFavoriteActivityUseCase.swift
//  CoordinateDomain
//

import Foundation

public struct ToggleFavoriteActivityUseCase: Sendable {
    public init() {}

    public enum Outcome: Equatable, Sendable {
        case favorited
        case unfavorited
    }

    public func execute(
        activityID: UUID,
        favoriteIDs: inout Set<UUID>
    ) -> Outcome {
        if favoriteIDs.contains(activityID) {
            favoriteIDs.remove(activityID)
            return .unfavorited
        }
        favoriteIDs.insert(activityID)
        return .favorited
    }
}
