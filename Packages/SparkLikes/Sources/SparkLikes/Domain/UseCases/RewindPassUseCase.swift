// Module: SparkLikes — Undo last pass (daily limit).

import Foundation

struct RewindPassUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    public func callAsFunction() async throws -> DiscoverCard? {
        try await repository.rewindLastPass()
    }
}
