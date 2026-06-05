// Module: SparkCommunity — Community detail screen state.

import Foundation
import Observation

@MainActor
@Observable
public final class CommunityDetailViewModel {
    public enum Segment: String, CaseIterable, Sendable {
        case activities
        case posts
    }

    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failure(String)
    }

    public private(set) var loadState: LoadState = .idle
    public private(set) var detail: CommunityDetail?
    public private(set) var activities: [CommunityLinkedActivity] = []
    public private(set) var members: [CommunityMember] = []
    public private(set) var posts: [CommunityFeedPost] = []
    public var selectedSegment: Segment = .posts

    private let communityID: String
    private let repository: any CommunityPostsRepository

    public init(communityID: String, repository: any CommunityPostsRepository) {
        self.communityID = communityID
        self.repository = repository
    }

    public func load() async {
        loadState = .loading
        do {
            async let detailTask = repository.fetchCommunityDetail(id: communityID)
            async let activitiesTask = repository.fetchCommunityActivities(communityID: communityID)
            async let membersTask = repository.fetchCommunityMembers(communityID: communityID)
            async let postsTask = repository.fetchCommunityPosts(communityID: communityID)

            let loadedDetail = try await detailTask
            detail = loadedDetail
            activities = try await activitiesTask
            members = try await membersTask
            posts = try await postsTask
            loadState = .loaded
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }
}
