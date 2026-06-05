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

    public enum ReplyState: Equatable, Sendable {
        case idle
        case sending
        case failure(String)
    }

    public let postID: String
    public private(set) var post: CommunityPostDetail?
    public private(set) var loadState: LoadState = .idle
    public private(set) var replyState: ReplyState = .idle
    public var replyDraft = ""

    private let fetchPost: FetchCommunityPostUseCase
    private let createReply: CreateCommunityReplyUseCase

    public init(postID: String, repository: any CommunityPostsRepository) {
        self.postID = postID
        fetchPost = FetchCommunityPostUseCase(repository: repository)
        createReply = CreateCommunityReplyUseCase(repository: repository)
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

    public func sendReply() async {
        let body = replyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        replyState = .sending
        do {
            let reply = try await createReply(postID: postID, body: body)
            if var current = post {
                var replies = current.replies
                replies.append(reply)
                post = CommunityPostDetail(
                    id: current.id,
                    title: current.title,
                    body: current.body,
                    authorDisplayName: current.authorDisplayName,
                    replyCount: replies.count,
                    replies: replies
                )
            }
            replyDraft = ""
            replyState = .idle
        } catch is CancellationError {
            replyState = .idle
        } catch {
            replyState = .failure(error.localizedDescription)
        }
    }
}
