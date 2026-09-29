//
//  BuddiesBookingTypes.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public enum BookingStatusTransition: Sendable, Equatable {
    case accept
    case decline
    case withdraw
    case beginPayment
    case confirmPayment
    case markInProgress
    case complete
    case cancel
    case refund
    case completeRefund
    case rejectRefund
    case expirePayment
    case expireConfirmation
}

public enum BookingStatusTransitionFailure: Equatable, Error, Sendable {
    case recordNotFound
    case invalidTransition
    case notPayable
}
