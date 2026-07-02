// Module: SparkCommunity — Community post detail state.

import Foundation
import Observation
import SparkCore

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

    public enum ReportState: Equatable, Sendable {
        case idle
        case submitting
        case submitted
        case failure(String)
    }

    public let postID: String
    public private(set) var post: CommunityPostDetail?
    public private(set) var loadState: LoadState = .idle
    public private(set) var replyState: ReplyState = .idle
    public private(set) var reportState: ReportState = .idle
    public private(set) var isLikePending = false
    public var replyDraft = ""
    public var replySortMode: CommunityPostReplySortMode = .participantsFirst

    private let fetchPost: any FetchCommunityPostUseCaseProtocol
    private let createReply: any CreateCommunityReplyUseCaseProtocol
    private let reportPost: any ReportCommunityPostUseCaseProtocol
    private let setPostLike: any SetCommunityPostLikeUseCaseProtocol

    public init(
        postID: String,
        fetchPost: any FetchCommunityPostUseCaseProtocol,
        createReply: any CreateCommunityReplyUseCaseProtocol,
        reportPost: any ReportCommunityPostUseCaseProtocol,
        setPostLike: any SetCommunityPostLikeUseCaseProtocol
    ) {
        self.postID = postID
        self.fetchPost = fetchPost
        self.createReply = createReply
        self.reportPost = reportPost
        self.setPostLike = setPostLike
    }

    public var displayedReplies: [CommunityPostReply] {
        guard let post else { return [] }
        return CommunityPostReplySorting.sorted(post.replies, mode: replySortMode)
    }

    public var showsReplySortControl: Bool {
        post?.linkedActivity != nil && !(post?.replies.isEmpty ?? true)
    }

    public convenience init(postID: String, repository: any CommunityPostsRepository) {
        self.init(
            postID: postID,
            fetchPost: FetchCommunityPostUseCase(repository: repository),
            createReply: CreateCommunityReplyUseCase(repository: repository),
            reportPost: ReportCommunityPostUseCase(repository: repository),
            setPostLike: SetCommunityPostLikeUseCase(repository: repository)
        )
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

    public func toggleLike() async {
        guard let current = post, !isLikePending else { return }
        let targetLiked = !current.viewerHasLiked
        isLikePending = true
        let rollback = CommunityPostLikeResult(
            viewerHasLiked: current.viewerHasLiked,
            likeCount: current.likeCount
        )
        applyLikeResult(
            CommunityPostLikeResult(
                viewerHasLiked: targetLiked,
                likeCount: max(0, current.likeCount + (targetLiked ? 1 : -1))
            )
        )
        do {
            let result = try await setPostLike(postID: postID, liked: targetLiked)
            applyLikeResult(result)
            if targetLiked {
                IntegrationTelemetry.communityPostLiked(
                    postID: postID,
                    hasLinkedActivity: current.linkedActivity != nil
                )
            }
        } catch is CancellationError {
            applyLikeResult(rollback)
        } catch {
            applyLikeResult(rollback)
        }
        isLikePending = false
    }

    public func sendReply() async {
        let body = replyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        replyState = .sending
        do {
            let reply = try await createReply(postID: postID, body: body)
            if let current = post {
                var replies = current.replies
                replies.append(reply)
                let nextCount = max(current.replyCount, replies.count)
                post = CommunityPostDetail(
                    id: current.id,
                    title: current.title,
                    body: current.body,
                    authorDisplayName: current.authorDisplayName,
                    authorUserID: current.authorUserID,
                    replyCount: nextCount,
                    replies: replies,
                    linkedActivity: current.linkedActivity,
                    mediaItems: current.mediaItems,
                    tags: current.tags,
                    kind: current.kind,
                    likeCount: current.likeCount,
                    viewerHasLiked: current.viewerHasLiked
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

    public func submitReport(reason: CommunityReportReason, detail: String?) async {
        reportState = .submitting
        do {
            try await reportPost(postID: postID, reason: reason, detail: detail)
            reportState = .submitted
        } catch is CancellationError {
            reportState = .idle
        } catch {
            reportState = .failure(error.localizedDescription)
        }
    }

    public func dismissReportFeedback() {
        reportState = .idle
    }

    private func applyLikeResult(_ result: CommunityPostLikeResult) {
        guard let current = post else { return }
        post = CommunityPostDetail(
            id: current.id,
            title: current.title,
            body: current.body,
            authorDisplayName: current.authorDisplayName,
            authorUserID: current.authorUserID,
            replyCount: current.replyCount,
            replies: current.replies,
            linkedActivity: current.linkedActivity,
            mediaItems: current.mediaItems,
            tags: current.tags,
            kind: current.kind,
            likeCount: result.likeCount,
            viewerHasLiked: result.viewerHasLiked
        )
    }
}
