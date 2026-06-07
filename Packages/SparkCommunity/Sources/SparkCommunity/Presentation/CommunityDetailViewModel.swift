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
    public private(set) var joinState: JoinState = .idle

    public enum JoinState: Equatable, Sendable {
        case idle
        case joining
        case failure(String)
    }

    private let communityID: String
    private let fetchDetailBundle: any FetchCommunityDetailBundleUseCaseProtocol
    private let joinCommunity: any JoinCommunityUseCaseProtocol

    public init(
        communityID: String,
        fetchDetailBundle: any FetchCommunityDetailBundleUseCaseProtocol,
        joinCommunity: any JoinCommunityUseCaseProtocol
    ) {
        self.communityID = communityID
        self.fetchDetailBundle = fetchDetailBundle
        self.joinCommunity = joinCommunity
    }

    public convenience init(communityID: String, repository: any CommunityPostsRepository) {
        self.init(
            communityID: communityID,
            fetchDetailBundle: FetchCommunityDetailBundleUseCase(repository: repository),
            joinCommunity: JoinCommunityUseCase(repository: repository)
        )
    }

    public var isJoining: Bool {
        if case .joining = joinState { return true }
        return false
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

    public func join() async {
        guard detail?.isJoined == false else { return }
        joinState = .joining
        do {
            detail = try await joinCommunity(communityID: communityID)
            joinState = .idle
        } catch is CancellationError {
            joinState = .idle
        } catch {
            joinState = .failure(error.localizedDescription)
        }
    }

    public func dismissJoinError() {
        if case .failure = joinState {
            joinState = .idle
        }
    }
}
