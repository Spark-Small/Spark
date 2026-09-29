//
//  APIEndpoint+Bookings.swift
//  坐标系
//
//  陪玩预约远程接单：提交与状态查询（FR-BUD-09 / Phase C）。
//

import CoordinateNetworking
import Foundation
import CoordinateModels

extension APIEndpoint where Response == BuddyBookingRecord {
    static func submitBooking(_ record: BuddyBookingRecord) throws -> APIEndpoint<BuddyBookingRecord> {
        APIEndpoint(
            path: "buddies/bookings",
            method: .post,
            body: try JSONEncoder().encode(record)
        )
    }

    static func bookingDetail(id: UUID) -> APIEndpoint<BuddyBookingRecord> {
        APIEndpoint(path: "buddies/bookings/\(id.uuidString.lowercased())")
    }
}
