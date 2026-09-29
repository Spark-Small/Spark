//
//  SwiftDataSnapshotRegistry.swift
//  坐标系
//
//  五域 + engagement SwiftData 快照注册、@ModelActor 注入与启动预热。
//

import CoordinateData
import CoordinateDomain
import CoordinateModels
import SwiftData

@MainActor
enum SwiftDataSnapshotRegistry {
    private(set) static var snapshotActor: DomainSnapshotModelActor!
    private(set) static var activities: SwiftDataSnapshotGateway<ActivitiesSnapshot>!
    private(set) static var messages: SwiftDataSnapshotGateway<MessagesSnapshot>!
    private(set) static var buddies: SwiftDataSnapshotGateway<BuddiesSnapshot>!
    private(set) static var community: SwiftDataSnapshotGateway<CommunitySnapshot>!
    private(set) static var profile: SwiftDataSnapshotGateway<ProfileSnapshot>!
    private(set) static var engagement: SwiftDataSnapshotGateway<ActivityEngagementSnapshot>!

    private static var gateways: [any SwiftDataSnapshotGatewayProtocol] = []

    static func attach(container: ModelContainer) {
        snapshotActor = DomainSnapshotModelActor(modelContainer: container)

        let activitiesPolicy = AppActivitiesSnapshotPolicy()
        let messagesPolicy = AppMessagesSnapshotPolicy()
        let buddiesPolicy = AppBuddiesSnapshotPolicy()
        let communityPolicy = AppCommunitySnapshotPolicy()
        let profilePolicy = AppProfileSnapshotPolicy()
        let engagementPolicy = AppEngagementSnapshotPolicy()

        activities = makeGateway(
            domainKey: SnapshotDomainKey.activities,
            legacyFileName: "activities_snapshot.json",
            fallback: { activitiesPolicy.fallbackSnapshot() },
            afterLoad: { loaded in
                guard activitiesPolicy.needsRepairOnLoad(loaded) else {
                    return (loaded, false)
                }
                return (activitiesPolicy.repairSnapshot(from: loaded), true)
            }
        )

        messages = makeGateway(
            domainKey: SnapshotDomainKey.messages,
            legacyFileName: "messages_snapshot.json",
            fallback: { messagesPolicy.fallbackSnapshot() },
            afterLoad: messagesPolicy.afterLoad
        )

        buddies = makeGateway(
            domainKey: SnapshotDomainKey.buddies,
            legacyFileName: "buddies_snapshot.json",
            fallback: { buddiesPolicy.fallbackSnapshot() }
        )

        community = makeGateway(
            domainKey: SnapshotDomainKey.community,
            legacyFileName: "community_snapshot.json",
            fallback: { communityPolicy.fallbackSnapshot() },
            afterLoad: communityPolicy.afterLoad
        )

        profile = makeGateway(
            domainKey: SnapshotDomainKey.profile,
            legacyFileName: "profile_snapshot.json",
            fallback: { profilePolicy.fallbackSnapshot() }
        )

        engagement = makeGateway(
            domainKey: SnapshotDomainKey.engagement,
            legacyFileName: "activity_engagement_snapshot.json",
            fallback: { engagementPolicy.fallbackSnapshot() }
        )

        gateways = [activities, messages, buddies, community, profile, engagement]
    }

    /// 在构造 `AppModel` 之前调用，预热各域内存缓存并完成 JSON 迁移。
    static func bootstrap() async {
        for gateway in gateways {
            await gateway.bootstrap()
        }
    }

    private static func makeGateway<Snapshot: Codable & Sendable>(
        domainKey: String,
        legacyFileName: String,
        fallback: @escaping @Sendable () -> Snapshot,
        afterLoad: SwiftDataSnapshotGateway<Snapshot>.AfterLoad? = nil
    ) -> SwiftDataSnapshotGateway<Snapshot> {
        SwiftDataSnapshotGateway(
            domainKey: domainKey,
            legacyFileName: legacyFileName,
            fallback: fallback,
            afterLoad: afterLoad,
            actor: snapshotActor
        )
    }
}

@MainActor
private protocol SwiftDataSnapshotGatewayProtocol {
    func bootstrap() async
    func awaitPendingSave() async
}

extension SwiftDataSnapshotGateway: SwiftDataSnapshotGatewayProtocol {}

extension SwiftDataSnapshotRegistry {
    /// 等待所有 Gateway 串联写完成（配合 `AppModel.flushPersistenceForBackground`）。
    static func awaitAllPendingSaves() async {
        for gateway in gateways {
            await gateway.awaitPendingSave()
        }
    }
}
