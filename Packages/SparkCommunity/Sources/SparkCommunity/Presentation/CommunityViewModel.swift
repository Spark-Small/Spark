// Module: SparkCommunity — Community feed state.

import Foundation
import Observation

@MainActor
@Observable
public final class CommunityViewModel {
    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case empty
        case failure(String)
    }

    public private(set) var posts: [CommunityPost] = []
    public private(set) var loadState: LoadState = .idle

    private let fetchPosts: FetchCommunityPostsUseCase

    public init(repository: any CommunityPostsRepository) {
        fetchPosts = FetchCommunityPostsUseCase(repository: repository)
    }

    public func load() async {
        loadState = .loading
        do {
            posts = try await fetchPosts()
            loadState = posts.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }
}
