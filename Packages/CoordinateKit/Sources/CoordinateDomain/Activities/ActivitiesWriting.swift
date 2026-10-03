//
//  ActivitiesWriting.swift
//  CoordinateDomain
//
//  活动写路径协议：Local 实现走 Domain UC + 快照；Remote 实现后续接 API。
//

import Foundation
import CoordinateModels

/// 活动写操作的领域意图（与网络解耦）。
public enum ActivitiesWriteCommand: Equatable, Sendable {
    case publish(PublishActivityDraft)
    case update(UpdateActivityDraft)
    case cancel(activityID: UUID)
    case updateCapacity(activityID: UUID, capacity: Int)
    case reschedule(activityID: UUID, date: Date)
    case toggleFavorite(activityID: UUID)
    case join(activityID: UUID)
    case leave(activityID: UUID)
    case toggleWaitlist(activityID: UUID)
}

/// 可变报名快照切片，供 Local writer 应用 UC。
public struct ActivitiesWritableState: Sendable {
    public var activities: [Activity]
    public var joinedIDs: Set<UUID>
    public var favoriteIDs: Set<UUID>
    public var waitlistIDs: Set<UUID>
    public var waitlistSpotNotifiedIDs: Set<UUID>

    public init(
        activities: [Activity],
        joinedIDs: Set<UUID>,
        favoriteIDs: Set<UUID>,
        waitlistIDs: Set<UUID>,
        waitlistSpotNotifiedIDs: Set<UUID>
    ) {
        self.activities = activities
        self.joinedIDs = joinedIDs
        self.favoriteIDs = favoriteIDs
        self.waitlistIDs = waitlistIDs
        self.waitlistSpotNotifiedIDs = waitlistSpotNotifiedIDs
    }
}

/// Local 写路径：纯 Domain UC，无网络。Feature Model 负责副作用与 persist。
public struct LocalActivitiesWriter: Sendable {
    public var participation: ActivitiesParticipationUseCases
    public var hosting: ActivitiesHostingUseCases

    public init(
        participation: ActivitiesParticipationUseCases = ActivitiesParticipationUseCases(),
        hosting: ActivitiesHostingUseCases = ActivitiesHostingUseCases()
    ) {
        self.participation = participation
        self.hosting = hosting
    }

    public func applyPublish(
        draft: PublishActivityDraft,
        to state: inout ActivitiesWritableState
    ) -> Result<UUID, PublishActivityFailure> {
        hosting.publish.execute(
            draft: draft,
            activities: &state.activities,
            joinedIDs: &state.joinedIDs
        )
    }

    public func applyUpdate(
        draft: UpdateActivityDraft,
        hostName: String,
        hostUserID: UUID?,
        to state: inout ActivitiesWritableState
    ) -> Result<Void, UpdateActivityFailure> {
        hosting.update.execute(
            draft: draft,
            activities: &state.activities,
            hostName: hostName,
            hostUserID: hostUserID
        )
    }

    public func applyCancel(
        activityID: UUID,
        hostName: String,
        hostUserID: UUID?,
        to state: inout ActivitiesWritableState
    ) -> Result<CancelActivityResult, CancelActivityFailure> {
        hosting.cancel.execute(
            activityID: activityID,
            activities: &state.activities,
            joinedIDs: &state.joinedIDs,
            favoriteIDs: &state.favoriteIDs,
            waitlistIDs: &state.waitlistIDs,
            hostName: hostName,
            hostUserID: hostUserID
        )
    }
}
