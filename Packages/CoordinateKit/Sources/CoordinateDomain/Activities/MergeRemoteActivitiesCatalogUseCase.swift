//
//  MergeRemoteActivitiesCatalogUseCase.swift
//  CoordinateDomain
//
//  远程目录合并：保留本地用户自建与报名态，禁止整包覆盖。
//

import Foundation
import CoordinateModels

public struct MergeRemoteActivitiesCatalogUseCase: Sendable {
    public init() {}

    /// - Parameters:
    ///   - remote: 远程目录快照（通常只含 `activities`）
    ///   - previous: 本机当前快照
    ///   - knownSeedIDs: 可选；若提供，则 previous 中不在 remote 且不在 seed 的活动视为用户自建并保留
    public func execute(
        remote: ActivitiesSnapshot,
        previous: ActivitiesSnapshot,
        knownSeedIDs: Set<UUID> = []
    ) -> ActivitiesSnapshot {
        let remoteIDs = Set(remote.activities.map(\.id))
        let userCreated = previous.activities.filter { activity in
            !remoteIDs.contains(activity.id)
                && (knownSeedIDs.isEmpty || !knownSeedIDs.contains(activity.id))
        }

        var catalog = remote.activities
        catalog.append(contentsOf: userCreated)

        let validIDs = Set(catalog.map(\.id))
        return ActivitiesSnapshot(
            activities: catalog,
            joinedIDs: previous.joinedIDs.filter(validIDs.contains),
            favoriteIDs: previous.favoriteIDs.filter(validIDs.contains),
            waitlistIDs: previous.waitlistIDs.filter(validIDs.contains),
            waitlistSpotNotifiedIDs: previous.waitlistSpotNotifiedIDs.filter(validIDs.contains),
            participationProgress: previous.participationProgress.filter {
                validIDs.contains($0.activityID)
            },
            feedbackTagCounts: previous.feedbackTagCounts.filter { key, _ in
                guard let id = UUID(uuidString: key) else { return false }
                return validIDs.contains(id)
            }
        )
    }
}
