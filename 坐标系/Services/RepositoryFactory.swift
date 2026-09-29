//
//  RepositoryFactory.swift
//  坐标系
//

import CoordinateData
import CoordinateDomain
import CoordinateFeatureFlags
import Foundation

struct AppRepositories {
    var activities: any ActivitiesRepository
    var messages: any MessagesRepository
    var buddies: any BuddiesRepository
    var community: any CommunityRepository
    var profile: any ProfileRepository

    @MainActor
    static var live: AppRepositories {
        FeatureFlags.migrateLegacyFlagsIfNeeded()
        return AppRepositories(
            activities: AppComposition.makeActivitiesRepository(),
            messages: AppComposition.makeMessagesRepository(),
            buddies: AppComposition.makeBuddiesRepository(),
            community: AppComposition.makeCommunityRepository(),
            profile: AppComposition.makeProfileRepository()
        )
    }

    @MainActor
    static func inMemoryForTests(
        activities: ActivitiesSnapshot = .seed,
        messages: MessagesSnapshot = .seed,
        buddies: BuddiesSnapshot = BuddiesSnapshot(
            inviteRecords: [],
            bookingRecords: [],
            joinedCircleNames: []
        ),
        community: CommunitySnapshot = .emptySeed,
        profile: ProfileSnapshot = .seed
    ) -> AppRepositories {
        AppRepositories(
            activities: InMemoryActivitiesRepository(snapshot: activities),
            messages: InMemoryMessagesRepository(snapshot: messages),
            buddies: InMemoryBuddiesRepository(snapshot: buddies),
            community: InMemoryCommunityRepository(snapshot: community),
            profile: InMemoryProfileRepository(snapshot: profile)
        )
    }
}
