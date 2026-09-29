//
//  ExpireOverdueBookingConfirmationsUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct ExpireOverdueBookingConfirmationsUseCase: Sendable {
    public init() {}

    public func overdueIDs(
        in records: [BuddyBookingRecord],
        now: Date = .now
    ) -> [BuddyBookingRecord.ID] {
        records.filter { $0.isConfirmationOverdue(at: now) }.map(\.id)
    }
}
