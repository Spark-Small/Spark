// Module: SparkLikesTests

@testable import SparkLikes
import Foundation
import SparkCore
import Testing

struct LikesDTOMapperTests {
    @Test func inboundItemParsesISO8601LikedAt() throws {
        let json = """
        {
          "user_id": "u1",
          "liked_at": "2026-06-05T12:00:00Z",
          "card": {
            "user_id": "u1",
            "display_name": "Test",
            "bio": "Bio",
            "gender": "female",
            "media": { "kind": "image", "url": "https://example.com/a.jpg" }
          }
        }
        """
        let dto = try JSONDecoder().decode(InboundLikeItemDTO.self, from: Data(json.utf8))
        let item = try #require(LikesDTOMapper.inboundItem(from: dto))
        #expect(item.likedAt != nil)
    }

    @Test func inboundItemParsesFractionalISO8601() throws {
        let json = """
        {
          "user_id": "u1",
          "liked_at": "2026-06-05T12:00:00.123Z",
          "card": {
            "user_id": "u1",
            "display_name": "Test",
            "media": { "kind": "image", "url": "https://example.com/a.jpg" }
          }
        }
        """
        let dto = try JSONDecoder().decode(InboundLikeItemDTO.self, from: Data(json.utf8))
        let item = try #require(LikesDTOMapper.inboundItem(from: dto))
        #expect(item.likedAt != nil)
    }

    @Test func cardMapsSharedActivity() throws {
        let json = """
        {
          "user_id": "u1",
          "display_name": "Test",
          "media": { "kind": "image", "url": "https://example.com/a.jpg" },
          "shared_activity": { "activity_id": "act_1", "title": "Walk" }
        }
        """
        let dto = try JSONDecoder().decode(DiscoverCardDTO.self, from: Data(json.utf8))
        let card = try #require(LikesDTOMapper.card(from: dto))
        #expect(card.sharedActivityID == "act_1")
        #expect(card.sharedActivityTitle == "Walk")
    }
}

struct LikesErrorPresentationTests {
    @Test func networkErrorIncludesRecovery() {
        let error = LikesError.underlying(.networkUnavailable)
        let facing = LikesUserFacingError.from(error)
        #expect(facing.recoverySuggestion != nil)
        #expect(facing.displayText.contains(facing.message))
    }

    @Test func rewindUnavailableRecovery() {
        let facing = LikesUserFacingError.from(LikesError.rewindUnavailable)
        #expect(facing.recoverySuggestion != nil)
    }
}
