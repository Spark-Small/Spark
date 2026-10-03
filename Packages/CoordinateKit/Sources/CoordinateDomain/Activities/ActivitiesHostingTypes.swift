//
//  ActivitiesHostingTypes.swift
//  CoordinateDomain
//
//  发起人写路径：草稿 DTO 与失败类型（纯领域，无 UI / 持久化）。
//

import Foundation
import CoordinateModels

public struct PublishActivityDraft: Equatable, Sendable {
    public var title: String
    public var category: ActivityCategory
    public var location: String
    public var date: Date
    public var capacity: Int
    public var fee: String
    public var freeFeeLabel: String
    public var summary: String
    public var tags: [String]
    public var localCoverName: String?
    public var distanceKM: Double
    public var latitude: Double?
    public var longitude: Double?
    public var hostName: String
    public var hostUserID: UUID?

    public init(
        title: String,
        category: ActivityCategory,
        location: String,
        date: Date,
        capacity: Int,
        fee: String,
        freeFeeLabel: String,
        summary: String,
        tags: [String],
        localCoverName: String?,
        distanceKM: Double,
        latitude: Double?,
        longitude: Double?,
        hostName: String,
        hostUserID: UUID?
    ) {
        self.title = title
        self.category = category
        self.location = location
        self.date = date
        self.capacity = capacity
        self.fee = fee
        self.freeFeeLabel = freeFeeLabel
        self.summary = summary
        self.tags = tags
        self.localCoverName = localCoverName
        self.distanceKM = distanceKM
        self.latitude = latitude
        self.longitude = longitude
        self.hostName = hostName
        self.hostUserID = hostUserID
    }
}

public struct UpdateActivityDraft: Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var category: ActivityCategory
    public var location: String
    public var date: Date
    public var capacity: Int
    public var fee: String
    public var freeFeeLabel: String
    public var summary: String
    public var tags: [String]
    public var localCoverName: String?
    public var latitude: Double?
    public var longitude: Double?
    public var distanceKM: Double?

    public init(
        id: UUID,
        title: String,
        category: ActivityCategory,
        location: String,
        date: Date,
        capacity: Int,
        fee: String,
        freeFeeLabel: String,
        summary: String,
        tags: [String],
        localCoverName: String?,
        latitude: Double?,
        longitude: Double?,
        distanceKM: Double?
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.location = location
        self.date = date
        self.capacity = capacity
        self.fee = fee
        self.freeFeeLabel = freeFeeLabel
        self.summary = summary
        self.tags = tags
        self.localCoverName = localCoverName
        self.latitude = latitude
        self.longitude = longitude
        self.distanceKM = distanceKM
    }
}

public enum PublishActivityFailure: Equatable, Error, Sendable {
    case invalidFields
    case browseAggregateCategory
}

public enum UpdateActivityFailure: Equatable, Error, Sendable {
    case activityNotFound
    case notHost
    case invalidFields
    case browseAggregateCategory
}

public enum CancelActivityFailure: Equatable, Error, Sendable {
    case activityNotFound
    case notHost
}

public struct CancelActivityResult: Equatable, Sendable {
    public let coverName: String?

    public init(coverName: String?) {
        self.coverName = coverName
    }
}

public enum UpdateCapacityFailure: Equatable, Error, Sendable {
    case activityNotFound
    case notHost
    case unchanged
}

public struct UpdateCapacityResult: Equatable, Sendable {
    public let capacity: Int
    public let openedSpotFromFull: Bool

    public init(capacity: Int, openedSpotFromFull: Bool) {
        self.capacity = capacity
        self.openedSpotFromFull = openedSpotFromFull
    }
}

public enum RescheduleActivityFailure: Equatable, Error, Sendable {
    case activityNotFound
    case notHost
    case dateNotInFuture
}
