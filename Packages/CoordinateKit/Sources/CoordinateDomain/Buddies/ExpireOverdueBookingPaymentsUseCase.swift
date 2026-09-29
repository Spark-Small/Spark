//
//  ExpireOverdueBookingPaymentsUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct ExpireOverdueBookingPaymentsUseCase: Sendable {
    public init() {}

    public func overdueIDs(
        in records: [BuddyBookingRecord],
        now: Date = .now
    ) -> [BuddyBookingRecord.ID] {
        records.filter { $0.isPaymentOverdue(at: now) }.map(\.id)
    }
}
