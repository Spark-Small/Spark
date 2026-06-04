// Module: SparkCommunity — Community post detail state.

import Foundation
import Observation

@MainActor
@Observable
public final class CommunityPostDetailViewModel {
    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failure(String)
    }

    public let postID: String
    public private(set) var post: CommunityPostDetail?
    public private(set) var loadState: LoadState = .idle

    private let fetchPost: FetchCommunityPostUseCase

    public init(postID: String, repository: any CommunityPostsRepository) {
        self.postID = postID
        fetchPost = FetchCommunityPostUseCase(repository: repository)
    }

    public func load() async {
        loadState = .loading
        do {
            post = try await fetchPost(postID: postID)
            loadState = .loaded
        } catch is CancellationError {
            return
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }
}
