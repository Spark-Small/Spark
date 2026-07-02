// Module: SparkAppShell — Bundled tab-level dependencies (constructor injection).

import SparkActivity
import SparkBuddy
import SparkCommunity
import SparkMessages
import SparkProfile
import SparkSearch
import SparkTrust

public struct SparkTabDependencies: Sendable {
    public let peerDisplayNameStorage: any PeerDisplayNameStoring
    public let messagesCoordinator: MessagesCoordinator
    public let activityCoordinator: ActivityCoordinator
    public let communityCoordinator: CommunityCoordinator
    public let profileCoordinator: ProfileCoordinator
    public let buddyCoordinator: BuddyCoordinator
    public let orchestrator: SparkTabOrchestrator

    public init(
        messagesRepository: any MessagesRepository,
        activityFeedRepository: any ActivityFeedRepository,
        activityBrowseRepository: any ActivityBrowseRepository,
        searchRepository: any SearchRepository,
        buddyRepository: any BuddyRepository,
        communityPostsRepository: any CommunityPostsRepository,
        prepareCommunityMediaUpload: (any PrepareCommunityMediaUploadUseCaseProtocol)? = nil,
        trustRepository: any TrustRepository,
        blockedActivityHostsStore: BlockedActivityHostsStore,
        peerDisplayNameStorage: (any PeerDisplayNameStoring)? = nil
    ) {
        self.peerDisplayNameStorage = peerDisplayNameStorage ?? UserDefaultsPeerDisplayNameStore()
        messagesCoordinator = MessagesCoordinator(repository: messagesRepository)
        activityCoordinator = ActivityCoordinator(
            feedRepository: activityFeedRepository,
            blockedHostsStore: blockedActivityHostsStore,
            browseRepository: activityBrowseRepository
        )
        communityCoordinator = CommunityCoordinator(
            repository: communityPostsRepository,
            prepareMediaUpload: prepareCommunityMediaUpload ?? PrepareCommunityMediaUploadUseCase()
        )
        profileCoordinator = ProfileCoordinator(
            trustRepository: trustRepository,
            searchRepository: searchRepository
        )
        buddyCoordinator = BuddyCoordinator(repository: buddyRepository)
        orchestrator = SparkTabOrchestrator(
            messagesCoordinator: messagesCoordinator,
            activityCoordinator: activityCoordinator,
            buddyCoordinator: buddyCoordinator
        )
    }
}
