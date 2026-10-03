//
//  ActivityComposeSupport.swift
//  坐标系
//
//  发起页辅助：草稿暂存、提交载荷。
//

import Foundation
import CoordinateModels

// MARK: - Publish / update payload

struct ActivityComposePayload: Equatable, Sendable {
    var title: String
    var category: ActivityCategory
    var location: String
    var date: Date
    var capacity: Int
    var fee: String
    var summary: String
    var tags: [String]
    var localCoverName: String?
    var latitude: Double?
    var longitude: Double?
}

// MARK: - Draft store

struct ActivityComposeDraftSnapshot: Codable, Equatable {
    var title: String
    var categoryRaw: String
    var location: String
    var date: Date
    var endDate: Date
    var capacity: Int
    var feeKindRaw: String
    var feeAmountText: String
    var feeAAEstimateText: String
    var summary: String
    var tags: [String]
    var localCoverName: String?
    var galleryPhotoNames: [String]
    var latitude: Double?
    var longitude: Double?
}

enum ActivityComposeDraftStore {
    private static let keyPrefix = "compose.activityDraft."

    private static func key(for userID: UUID) -> String {
        keyPrefix + userID.uuidString
    }

    static func load(userID: UUID = LocalUserIdentity.current) -> ActivityComposeDraftSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: key(for: userID)) else { return nil }
        return try? JSONDecoder().decode(ActivityComposeDraftSnapshot.self, from: data)
    }

    static func save(_ snapshot: ActivityComposeDraftSnapshot, userID: UUID = LocalUserIdentity.current) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: key(for: userID))
    }

    static func clear(userID: UUID = LocalUserIdentity.current) {
        UserDefaults.standard.removeObject(forKey: key(for: userID))
    }
}
