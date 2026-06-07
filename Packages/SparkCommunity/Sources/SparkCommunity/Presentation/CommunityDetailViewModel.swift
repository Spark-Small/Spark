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
    private let fetchDetailBundle: FetchCommunityDetailBundleUseCase

    public init(communityID: String, repository: any CommunityPostsRepository) {
        self.communityID = communityID
        fetchDetailBundle = FetchCommunityDetailBundleUseCase(repository: repository)
    }

    public func load() async {
        loadState = .loading
        do {
            let bundle = try await fetchDetailBundle(communityID: communityID)
            detail = bundle.detail
            activities = bundle.activities
            members = bundle.members
            posts = bundle.posts
            loadState = .loaded
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }
}
