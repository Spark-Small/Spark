//
//  ActivitiesParticipationTypes.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public enum JoinActivityFailure: Equatable, Error, Sendable {
    case activityNotFound
    case alreadyJoined
    case alreadyFull
    case lifecycleEnded
}

public enum LeaveActivityFailure: Equatable, Error, Sendable {
    case activityNotFound
    case notJoined
}

public enum ToggleWaitlistResult: Equatable, Sendable {
    case joined
    case left
    case unnecessary
    case activityNotFound
}

public enum PromoteFromWaitlistFailure: Equatable, Error, Sendable {
    case notOnWaitlist
    case notJoinable
    case paymentRequired
    case joinFailed(JoinActivityFailure)
}

public enum WaitlistSpotEffect: Equatable, Sendable {
    case none
    case revoke(activityID: UUID)
    case notify(activityID: UUID, title: String)
}
