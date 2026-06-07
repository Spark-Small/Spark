// Module: SparkCommunity — Submit UGC report for moderation queue.

import Foundation

public protocol ReportCommunityPostUseCaseProtocol: Sendable {
    func callAsFunction(postID: String, reason: CommunityReportReason, detail: String?) async throws
}

public struct ReportCommunityPostUseCase: Sendable, ReportCommunityPostUseCaseProtocol {
    private let repository: any CommunityPostsRepository

    public init(repository: any CommunityPostsRepository) {
        self.repository = repository
    }

    public func callAsFunction(
        postID: String,
        reason: CommunityReportReason,
        detail: String? = nil
    ) async throws {
        try await repository.reportPost(postID: postID, reason: reason, detail: detail)
    }
}
