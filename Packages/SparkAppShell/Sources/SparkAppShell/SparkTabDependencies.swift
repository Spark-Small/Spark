// Module: SparkAppShell — Bundled tab-level dependencies (constructor injection).

import SparkActivity
import SparkCommunity
import SparkLikes
import SparkMessages
import SparkProfile
import SparkSearch
import SparkTrust

public struct SparkTabDependencies: Sendable {
    public let messagesCoordinator: MessagesCoordinator
    public let activityCoordinator: ActivityCoordinator
    public let communityCoordinator: CommunityCoordinator
    public let likesCoordinator: LikesCoordinator
    public let profileCoordinator: ProfileCoordinator
    public let orchestrator: SparkTabOrchestrator

    public init(
        messagesRepository: any MessagesRepository,
        activityFeedRepository: any ActivityFeedRepository,
        activityBrowseRepository: any ActivityBrowseRepository,
        likesFeedRepository: any LikesFeedRepository,
        searchRepository: any SearchRepository,
        communityPostsRepository: any CommunityPostsRepository,
        trustRepository: any TrustRepository,
        blockedActivityHostsStore: BlockedActivityHostsStore,
        discoverMediaImageCache: DiscoverMediaImageCache,
        likesPreferencesStore: any LikesPreferencesStoring,
        likesOnboardingPreferences: any LikesOnboardingPreferences
    ) {
        messagesCoordinator = MessagesCoordinator(repository: messagesRepository)
        activityCoordinator = ActivityCoordinator(
            feedRepository: activityFeedRepository,
            blockedHostsStore: blockedActivityHostsStore,
            browseRepository: activityBrowseRepository
        )
        communityCoordinator = CommunityCoordinator(repository: communityPostsRepository)
        likesCoordinator = LikesCoordinator(
            repository: likesFeedRepository,
            preferencesStore: likesPreferencesStore,
            onboardingPreferences: likesOnboardingPreferences,
            discoverMediaImageCache: discoverMediaImageCache
        )
        profileCoordinator = ProfileCoordinator(
            trustRepository: trustRepository,
            searchRepository: searchRepository
        )
        orchestrator = SparkTabOrchestrator(
            messagesCoordinator: messagesCoordinator,
            activityCoordinator: activityCoordinator,
            likesCoordinator: likesCoordinator
        )
    }
}
