//
//  RemoteBookingSyncService.swift
//  坐标系
//
//  本地优先：提交预约到服务端，并轮询陪玩端回执（接单 / 拒单）。
//

import CoordinateFeatureFlags
import CoordinateModels
import CoordinateNetworking
import Foundation

protocol RemoteBookingSyncing: Sendable {
    var isEnabled: Bool { get }
    func submit(_ record: BuddyBookingRecord) async throws -> BuddyBookingRecord
    func fetchStatus(for id: UUID) async throws -> BuddyBookingRecord
}

struct DisabledRemoteBookingSync: RemoteBookingSyncing {
    var isEnabled: Bool { false }

    func submit(_ record: BuddyBookingRecord) async throws -> BuddyBookingRecord {
        record
    }

    func fetchStatus(for id: UUID) async throws -> BuddyBookingRecord {
        throw APIError.invalidResponse
    }
}

struct RemoteBookingSyncService: RemoteBookingSyncing {
    let client: APIClient

    var isEnabled: Bool { FeatureFlags.useRemoteBuddies }

    func submit(_ record: BuddyBookingRecord) async throws -> BuddyBookingRecord {
        try await client.send(try .submitBooking(record))
    }

    func fetchStatus(for id: UUID) async throws -> BuddyBookingRecord {
        try await client.send(.bookingDetail(id: id))
    }
}
