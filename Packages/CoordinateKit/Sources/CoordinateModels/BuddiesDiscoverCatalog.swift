//
//  BuddiesDiscoverCatalog.swift
//  CoordinateModels
//
//  远程发现目录 DTO（契约）；服务端未下发时客户端保持诚实空态。
//

import Foundation

public struct BuddiesDiscoverCatalog: Codable, Hashable, Sendable {
    public var freeBuddies: [BuddiesDiscoverBuddyDTO]
    public var paidCompanions: [BuddiesDiscoverCompanionDTO]

    public init(
        freeBuddies: [BuddiesDiscoverBuddyDTO] = [],
        paidCompanions: [BuddiesDiscoverCompanionDTO] = []
    ) {
        self.freeBuddies = freeBuddies
        self.paidCompanions = paidCompanions
    }

    public var isEmpty: Bool {
        freeBuddies.isEmpty && paidCompanions.isEmpty
    }
}

public struct BuddiesDiscoverBuddyDTO: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var userID: UUID?
    public var nickname: String
    public var gender: String
    public var age: Int
    public var city: String
    public var bio: String
    public var tags: [String]
    public var circleName: String
    public var topic: String
    public var isOnline: Bool
    public var availability: String
    public var lastActiveText: String
    public var lookingFor: String
    public var distanceKM: Double
    public var scheduleSlots: [String]
    public var relatedActivityTitles: [String]

    public init(
        id: UUID,
        userID: UUID? = nil,
        nickname: String,
        gender: String = "other",
        age: Int = 0,
        city: String = "",
        bio: String = "",
        tags: [String] = [],
        circleName: String = "",
        topic: String = "",
        isOnline: Bool = false,
        availability: String = "",
        lastActiveText: String = "",
        lookingFor: String = "",
        distanceKM: Double = 0,
        scheduleSlots: [String] = [],
        relatedActivityTitles: [String] = []
    ) {
        self.id = id
        self.userID = userID
        self.nickname = nickname
        self.gender = gender
        self.age = age
        self.city = city
        self.bio = bio
        self.tags = tags
        self.circleName = circleName
        self.topic = topic
        self.isOnline = isOnline
        self.availability = availability
        self.lastActiveText = lastActiveText
        self.lookingFor = lookingFor
        self.distanceKM = distanceKM
        self.scheduleSlots = scheduleSlots
        self.relatedActivityTitles = relatedActivityTitles
    }
}

public struct BuddiesDiscoverCompanionDTO: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var userID: UUID?
    public var nickname: String
    public var gender: String
    public var age: Int
    public var city: String
    public var bio: String
    public var tags: [String]
    public var serviceType: String
    public var specialty: String
    public var hourlyPrice: Int
    public var pricingUnit: String
    public var orderCount: Int
    public var isAvailable: Bool
    public var isVerified: Bool
    public var responseTime: String
    public var availability: String
    public var lastActiveText: String
    public var lookingFor: String
    public var distanceKM: Double
    public var scheduleSlots: [String]
    public var relatedActivityTitles: [String]

    public init(
        id: UUID,
        userID: UUID? = nil,
        nickname: String,
        gender: String = "other",
        age: Int = 0,
        city: String = "",
        bio: String = "",
        tags: [String] = [],
        serviceType: String = "voice",
        specialty: String = "",
        hourlyPrice: Int = 0,
        pricingUnit: String = "hour",
        orderCount: Int = 0,
        isAvailable: Bool = true,
        isVerified: Bool = false,
        responseTime: String = "",
        availability: String = "",
        lastActiveText: String = "",
        lookingFor: String = "",
        distanceKM: Double = 0,
        scheduleSlots: [String] = [],
        relatedActivityTitles: [String] = []
    ) {
        self.id = id
        self.userID = userID
        self.nickname = nickname
        self.gender = gender
        self.age = age
        self.city = city
        self.bio = bio
        self.tags = tags
        self.serviceType = serviceType
        self.specialty = specialty
        self.hourlyPrice = hourlyPrice
        self.pricingUnit = pricingUnit
        self.orderCount = orderCount
        self.isAvailable = isAvailable
        self.isVerified = isVerified
        self.responseTime = responseTime
        self.availability = availability
        self.lastActiveText = lastActiveText
        self.lookingFor = lookingFor
        self.distanceKM = distanceKM
        self.scheduleSlots = scheduleSlots
        self.relatedActivityTitles = relatedActivityTitles
    }
}
