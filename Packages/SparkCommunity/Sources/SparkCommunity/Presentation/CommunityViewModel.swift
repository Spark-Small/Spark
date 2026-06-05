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
    public private(set) var isCreatingPost = false
    public private(set) var createPostError: String?

    private let fetchPosts: FetchCommunityPostsUseCase
    private let createPostUseCase: CreateCommunityPostUseCase

    public init(repository: any CommunityPostsRepository) {
        fetchPosts = FetchCommunityPostsUseCase(repository: repository)
        createPostUseCase = CreateCommunityPostUseCase(repository: repository)
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

    @discardableResult
    public func createPost(_ draft: CreateCommunityPostDraft) async -> CommunityPost? {
        createPostError = nil
        guard draft.isValid else { return nil }
        isCreatingPost = true
        defer { isCreatingPost = false }
        do {
            let post = try await createPostUseCase(draft)
            posts.insert(post, at: 0)
            loadState = .loaded
            return post
        } catch is CancellationError {
            return nil
        } catch {
            createPostError = error.localizedDescription
            return nil
        }
    }
}
