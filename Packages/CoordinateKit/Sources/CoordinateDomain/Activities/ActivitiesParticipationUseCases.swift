//
//  ActivitiesParticipationUseCases.swift
//  CoordinateDomain
//

import Foundation

public struct ActivitiesParticipationUseCases: Sendable {
    public let join: JoinActivityUseCase
    public let leave: LeaveActivityUseCase
    public let toggleWaitlist: ToggleWaitlistUseCase
    public let promoteFromWaitlist: PromoteFromWaitlistUseCase
    public let evaluateWaitlistSpot: EvaluateWaitlistSpotUseCase
    public let repairSnapshot: RepairActivitiesSnapshotUseCase
    public let toggleFavorite: ToggleFavoriteActivityUseCase
    public let mergeRemoteCatalog: MergeRemoteActivitiesCatalogUseCase

    public init(
        join: JoinActivityUseCase = JoinActivityUseCase(),
        leave: LeaveActivityUseCase = LeaveActivityUseCase(),
        toggleWaitlist: ToggleWaitlistUseCase = ToggleWaitlistUseCase(),
        promoteFromWaitlist: PromoteFromWaitlistUseCase = PromoteFromWaitlistUseCase(),
        evaluateWaitlistSpot: EvaluateWaitlistSpotUseCase = EvaluateWaitlistSpotUseCase(),
        repairSnapshot: RepairActivitiesSnapshotUseCase = RepairActivitiesSnapshotUseCase(),
        toggleFavorite: ToggleFavoriteActivityUseCase = ToggleFavoriteActivityUseCase(),
        mergeRemoteCatalog: MergeRemoteActivitiesCatalogUseCase = MergeRemoteActivitiesCatalogUseCase()
    ) {
        self.join = join
        self.leave = leave
        self.toggleWaitlist = toggleWaitlist
        self.promoteFromWaitlist = promoteFromWaitlist
        self.evaluateWaitlistSpot = evaluateWaitlistSpot
        self.repairSnapshot = repairSnapshot
        self.toggleFavorite = toggleFavorite
        self.mergeRemoteCatalog = mergeRemoteCatalog
    }
}
