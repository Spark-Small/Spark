//
//  BuddiesBookingUseCases.swift
//  CoordinateDomain
//

import Foundation

public struct BuddiesBookingUseCases: Sendable {
    public let scheduleConflict: DetectBookingScheduleConflictUseCase
    public let statusTransition: ValidateBookingStatusTransitionUseCase
    public let applyTransition: ApplyBookingStatusTransitionUseCase
    public let expireOverduePayments: ExpireOverdueBookingPaymentsUseCase
    public let expireOverdueConfirmations: ExpireOverdueBookingConfirmationsUseCase
    public let reconcileRemote: ReconcileRemoteBookingRecordUseCase

    public init(
        scheduleConflict: DetectBookingScheduleConflictUseCase = DetectBookingScheduleConflictUseCase(),
        statusTransition: ValidateBookingStatusTransitionUseCase = ValidateBookingStatusTransitionUseCase(),
        applyTransition: ApplyBookingStatusTransitionUseCase = ApplyBookingStatusTransitionUseCase(),
        expireOverduePayments: ExpireOverdueBookingPaymentsUseCase = ExpireOverdueBookingPaymentsUseCase(),
        expireOverdueConfirmations: ExpireOverdueBookingConfirmationsUseCase = ExpireOverdueBookingConfirmationsUseCase(),
        reconcileRemote: ReconcileRemoteBookingRecordUseCase = ReconcileRemoteBookingRecordUseCase()
    ) {
        self.scheduleConflict = scheduleConflict
        self.statusTransition = statusTransition
        self.applyTransition = applyTransition
        self.expireOverduePayments = expireOverduePayments
        self.expireOverdueConfirmations = expireOverdueConfirmations
        self.reconcileRemote = reconcileRemote
    }
}
