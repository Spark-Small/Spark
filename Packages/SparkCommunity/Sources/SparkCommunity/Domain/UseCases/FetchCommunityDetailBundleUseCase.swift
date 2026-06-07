// Module: SparkCommunity — Parallel community detail load.

import Foundation

public struct CommunityDetailBundle: Sendable, Equatable {
    public let detail: CommunityDetail
    public let activities: [CommunityLinkedActivity]
    public let members: [CommunityMember]
    public let posts: [CommunityFeedPost]

    public init(
        detail: CommunityDetail,
        activities: [CommunityLinkedActivity],
        members: [CommunityMember],
        posts: [CommunityFeedPost]
    ) {
        self.detail = detail
        self.activities = activities
        self.members = members
        self.posts = posts
    }
}

public struct FetchCommunityDetailBundleUseCase: Sendable {
    private let repository: any CommunityPostsRepository

    public init(repository: any CommunityPostsRepository) {
        self.repository = repository
    }

    public func callAsFunction(communityID: String) async throws -> CommunityDetailBundle {
        async let detailTask = repository.fetchCommunityDetail(id: communityID)
        async let activitiesTask = repository.fetchCommunityActivities(communityID: communityID)
        async let membersTask = repository.fetchCommunityMembers(communityID: communityID)
        async let postsTask = repository.fetchCommunityPosts(communityID: communityID)

        return try await CommunityDetailBundle(
            detail: detailTask,
            activities: activitiesTask,
            members: membersTask,
            posts: postsTask
        )
    }
}
