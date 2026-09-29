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

    public init(
        join: JoinActivityUseCase = JoinActivityUseCase(),
        leave: LeaveActivityUseCase = LeaveActivityUseCase(),
        toggleWaitlist: ToggleWaitlistUseCase = ToggleWaitlistUseCase(),
        promoteFromWaitlist: PromoteFromWaitlistUseCase = PromoteFromWaitlistUseCase(),
        evaluateWaitlistSpot: EvaluateWaitlistSpotUseCase = EvaluateWaitlistSpotUseCase(),
        repairSnapshot: RepairActivitiesSnapshotUseCase = RepairActivitiesSnapshotUseCase()
    ) {
        self.join = join
        self.leave = leave
        self.toggleWaitlist = toggleWaitlist
        self.promoteFromWaitlist = promoteFromWaitlist
        self.evaluateWaitlistSpot = evaluateWaitlistSpot
        self.repairSnapshot = repairSnapshot
    }
}
