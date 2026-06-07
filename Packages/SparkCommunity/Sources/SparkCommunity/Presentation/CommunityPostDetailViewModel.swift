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
    public var replyDraft = ""

    private let fetchPost: any FetchCommunityPostUseCaseProtocol
    private let createReply: any CreateCommunityReplyUseCaseProtocol
    private let reportPost: any ReportCommunityPostUseCaseProtocol

    public init(
        postID: String,
        fetchPost: any FetchCommunityPostUseCaseProtocol,
        createReply: any CreateCommunityReplyUseCaseProtocol,
        reportPost: any ReportCommunityPostUseCaseProtocol
    ) {
        self.postID = postID
        self.fetchPost = fetchPost
        self.createReply = createReply
        self.reportPost = reportPost
    }

    public convenience init(postID: String, repository: any CommunityPostsRepository) {
        self.init(
            postID: postID,
            fetchPost: FetchCommunityPostUseCase(repository: repository),
            createReply: CreateCommunityReplyUseCase(repository: repository),
            reportPost: ReportCommunityPostUseCase(repository: repository)
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

    public func sendReply() async {
        let body = replyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        replyState = .sending
        do {
            let reply = try await createReply(postID: postID, body: body)
            if var current = post {
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
                    tags: current.tags
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
}
