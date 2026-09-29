//
//  RepairActivitiesSnapshotUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct RepairActivitiesSnapshotUseCase: Sendable {
    public init() {}

    /// 种子刷新目录活动；用户自建活动与报名 / 收藏 / 候补**只保留 previous**，
    /// 禁止把 seed 的 `joinedIDs` 再并回去（否则用户取消后会被静默重新报名）。
    public func execute(seed: ActivitiesSnapshot, previous: ActivitiesSnapshot) -> ActivitiesSnapshot {
        let seedIDs = Set(seed.activities.map(\.id))
        let userCreated = previous.activities.filter { !seedIDs.contains($0.id) }

        var catalog = seed.activities
        catalog.append(contentsOf: userCreated)

        let validIDs = Set(catalog.map(\.id))
        return ActivitiesSnapshot(
            activities: catalog,
            joinedIDs: previous.joinedIDs.filter(validIDs.contains),
            favoriteIDs: previous.favoriteIDs.filter(validIDs.contains),
            waitlistIDs: previous.waitlistIDs.filter(validIDs.contains),
            waitlistSpotNotifiedIDs: previous.waitlistSpotNotifiedIDs.filter(validIDs.contains),
            participationProgress: previous.participationProgress.filter { validIDs.contains($0.activityID) }
        )
    }
}
