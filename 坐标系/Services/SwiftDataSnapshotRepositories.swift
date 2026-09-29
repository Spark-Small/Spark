//
//  SwiftDataSnapshotRepositories.swift
//  坐标系
//
//  五域 SwiftData Repository 薄封装。
//

import CoordinateDomain
@preconcurrency import CoordinateModels
import Foundation

@MainActor
struct SwiftDataActivitiesRepository: ActivitiesRepository, SwiftDataSnapshotRepository {
    let persistenceKey: LocalPersistenceKey = .activities
    let swiftDataGateway: SwiftDataSnapshotGateway<ActivitiesSnapshot>

    init(gateway: SwiftDataSnapshotGateway<ActivitiesSnapshot>) {
        swiftDataGateway = gateway
    }

    func load() -> ActivitiesSnapshot { swiftDataGateway.load() }
    func save(_ snapshot: ActivitiesSnapshot) { swiftDataGateway.save(snapshot) }
}

@MainActor
struct SwiftDataMessagesRepository: MessagesRepository, SwiftDataSnapshotRepository {
    let persistenceKey: LocalPersistenceKey = .messages
    let swiftDataGateway: SwiftDataSnapshotGateway<MessagesSnapshot>

    init(gateway: SwiftDataSnapshotGateway<MessagesSnapshot>) {
        swiftDataGateway = gateway
    }

    func load() -> MessagesSnapshot { swiftDataGateway.load() }
    func save(_ snapshot: MessagesSnapshot) { swiftDataGateway.save(snapshot) }
}

@MainActor
struct SwiftDataBuddiesRepository: BuddiesRepository, SwiftDataSnapshotRepository {
    let persistenceKey: LocalPersistenceKey = .buddies
    let swiftDataGateway: SwiftDataSnapshotGateway<BuddiesSnapshot>

    init(gateway: SwiftDataSnapshotGateway<BuddiesSnapshot>) {
        swiftDataGateway = gateway
    }

    func load() -> BuddiesSnapshot { swiftDataGateway.load() }
    func save(_ snapshot: BuddiesSnapshot) { swiftDataGateway.save(snapshot) }
}

@MainActor
struct SwiftDataCommunityRepository: CommunityRepository, SwiftDataSnapshotRepository {
    let persistenceKey: LocalPersistenceKey = .community
    let swiftDataGateway: SwiftDataSnapshotGateway<CommunitySnapshot>

    init(gateway: SwiftDataSnapshotGateway<CommunitySnapshot>) {
        swiftDataGateway = gateway
    }

    func load() -> CommunitySnapshot { swiftDataGateway.load() }
    func save(_ snapshot: CommunitySnapshot) { swiftDataGateway.save(snapshot) }
}

@MainActor
struct SwiftDataProfileRepository: ProfileRepository, SwiftDataSnapshotRepository {
    let persistenceKey: LocalPersistenceKey = .profile
    let swiftDataGateway: SwiftDataSnapshotGateway<ProfileSnapshot>

    init(gateway: SwiftDataSnapshotGateway<ProfileSnapshot>) {
        swiftDataGateway = gateway
    }

    func load() -> ProfileSnapshot { swiftDataGateway.load() }
    func save(_ snapshot: ProfileSnapshot) { swiftDataGateway.save(snapshot) }
}

@MainActor
struct SwiftDataEngagementRepository: EngagementRepository, SwiftDataSnapshotRepository {
    let persistenceKey: LocalPersistenceKey = .engagement
    let swiftDataGateway: SwiftDataSnapshotGateway<ActivityEngagementSnapshot>

    init(gateway: SwiftDataSnapshotGateway<ActivityEngagementSnapshot>) {
        swiftDataGateway = gateway
    }

    func load() -> ActivityEngagementSnapshot { swiftDataGateway.load() }
    func save(_ snapshot: ActivityEngagementSnapshot) { swiftDataGateway.save(snapshot) }
}
