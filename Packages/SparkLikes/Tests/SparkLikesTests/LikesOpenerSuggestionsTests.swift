// Module: SparkLikesTests — Opener suggestion coverage.

import Foundation
import SparkCore
import SparkLikes
import Testing

struct LikesOpenerSuggestionsTests {
    @Test func baseSuggestionsAlwaysIncludeDefaults() throws {
        let card = try sampleCard()
        let lines = LikesOpenerSuggestions.suggestions(for: card)
        #expect(lines.count >= 3)
        #expect(lines.count <= 6)
    }

    @Test func suggestionsIncludeActivityTagQuestionAndProfileLines() throws {
        let photoURL = try #require(URL(string: "https://cdn.spark.test/photo.jpg"))
        let card = DiscoverCard(
            userID: UserID("u_1"),
            displayName: "Alex",
            bio: "Runner",
            gender: nil,
            media: DiscoverMedia(kind: .image, url: photoURL),
            interestTags: ["running"],
            sharedActivityTitle: "Morning Run",
            sparkQuestions: [SparkQuestion(id: "q_1", question: "Best trail?", answer: "Riverside")]
        )
        let lines = LikesOpenerSuggestions.suggestions(for: card)
        #expect(lines.contains { $0.contains("Morning Run") })
        #expect(lines.contains { $0.contains("running") })
        #expect(lines.contains { $0.contains("Best trail?") })
    }

    private func sampleCard() throws -> DiscoverCard {
        let photoURL = try #require(URL(string: "https://cdn.spark.test/base.jpg"))
        return DiscoverCard(
            userID: UserID("u_base"),
            displayName: "Sam",
            bio: "Hello",
            gender: nil,
            media: DiscoverMedia(kind: .image, url: photoURL)
        )
    }
}
