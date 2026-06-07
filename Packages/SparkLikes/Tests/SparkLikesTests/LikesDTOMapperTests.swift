// Module: SparkLikesTests — Likes DTO mapper coverage.

@testable import SparkLikes
import Foundation
import SparkCore
import Testing

struct LikesDTOMapperTests {
    @Test func pageMapsDiscoverCards() throws {
        let json = """
        {
          "items": [{
            "user_id": "u_like_1",
            "display_name": "Alex",
            "bio": "Runner",
            "media": {
              "kind": "image",
              "url": "https://cdn.spark.test/photo.jpg"
            },
            "interest_tags": ["running"],
            "is_daily_pick": true,
            "trust_score": 80
          }],
          "next_cursor": "cursor_2"
        }
        """
        let dto = try JSONDecoder().decode(LikesFeedResponseDTO.self, from: Data(json.utf8))
        let page = LikesDTOMapper.page(from: dto)
        #expect(page.items.count == 1)
        #expect(page.nextCursor == "cursor_2")
    }

    @Test func inboundPageMapsItems() throws {
        let json = """
        {
          "items": [{
            "user_id": "u_like_2",
            "card": {
              "user_id": "u_like_2",
              "display_name": "Sam",
              "media": {
                "kind": "image",
                "url": "https://cdn.spark.test/sam.jpg"
              }
            },
            "intensity": "spark",
            "is_visible": true,
            "opener": "Hi there"
          }],
          "next_cursor": null
        }
        """
        let dto = try JSONDecoder().decode(LikesInboundResponseDTO.self, from: Data(json.utf8))
        let page = LikesDTOMapper.inboundPage(from: dto)
        #expect(page.items.count == 1)
        #expect(page.items.first?.intensity == .spark)
    }

    @Test func sendLikeBodyMapsIntensityAndOpener() {
        let body = LikesDTOMapper.sendLikeBody(
            from: SendLikeRequest(
                userID: UserID("u_1"),
                intensity: .spark,
                opener: "Hello",
                likedQuestionID: "q_1"
            )
        )
        #expect(body.intensity == "spark")
        #expect(body.opener == "Hello")
    }

    @Test func dailyStatsMapping() throws {
        let json = """
        {
          "today_seen_count": 5,
          "daily_pool_size": 50,
          "spark_charges_remaining": 2
        }
        """
        let dto = try JSONDecoder().decode(DailyLikeStatsDTO.self, from: Data(json.utf8))
        let stats = LikesDTOMapper.dailyStats(from: dto)
        #expect(stats.todaySeenCount == 5)
        #expect(stats.sparkChargesRemaining == 2)
    }
}
