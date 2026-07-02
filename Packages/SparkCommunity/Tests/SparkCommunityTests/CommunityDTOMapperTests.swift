// Module: SparkCommunityTests — DTO mapping coverage.

@testable import SparkCommunity
import Foundation
import Testing

struct CommunityDTOMapperTests {
    @Test func postMapsFromDTO() throws {
        let json = """
        {
          "id": "cp_1",
          "title": "Title",
          "excerpt": "Excerpt",
          "author_display_name": "Alex",
          "reply_count": 2
        }
        """
        let dto = try JSONDecoder().decode(CommunityPostDTO.self, from: Data(json.utf8))
        let post = CommunityDTOMapper.post(from: dto)
        #expect(post.id == "cp_1")
        #expect(post.replyCount == 2)
    }

    @Test func postDetailMapsReplies() throws {
        let json = """
        {
          "id": "cp_2",
          "title": "Detail",
          "body": "Body",
          "author_display_name": "Sam",
          "author_user_id": "u_1",
          "reply_count": 1,
          "kind": "activity_recap",
          "linked_activity": {
            "id": "act_1",
            "name": "Coffee chat",
            "schedule_line": "Sat 9:30",
            "cover_url": "https://example.com/cover.jpg",
            "attendee_summary": "12 joined"
          },
          "replies": [
            {
              "id": "r_1",
              "body": "Reply",
              "author_display_name": "Guest",
              "created_at": "2026-06-07T10:00:00Z",
              "relationship_to_viewer": "attended_linked_activity"
            }
          ]
        }
        """
        let dto = try JSONDecoder().decode(CommunityPostDetailDTO.self, from: Data(json.utf8))
        let detail = CommunityDTOMapper.postDetail(from: dto)
        #expect(detail.replies.count == 1)
        #expect(detail.replies.first?.body == "Reply")
        #expect(detail.replies.first?.relationshipToViewer == .attendedLinkedActivity)
        #expect(detail.kind == .activityRecap)
        #expect(detail.linkedActivity?.scheduleLine == "Sat 9:30")
        #expect(detail.linkedActivity?.attendeeSummary == "12 joined")
    }

    @Test func tabExperienceMapsPostsAndPeopleDiscovery() throws {
        let json = """
        {
          "joined_communities": [{
            "id": "c_1",
            "name": "Runners",
            "cover_url": "https://example.com/cover.jpg",
            "member_count": 10,
            "activity_count": 2,
            "has_new_posts": true,
            "bio": "Weekly runs"
          }],
          "items": [
            {
              "type": "post",
              "post": {
                "id": "fp_1",
                "author_display_name": "Alex",
                "author_user_id": "u_1",
                "community_name": "Runners",
                "content": "Morning run",
                "like_count": 3,
                "comment_count": 1,
                "created_at": "2026-06-07T08:00:00Z",
                "relationship_to_viewer": "matched"
              }
            },
            {
              "type": "people_discovery",
              "people": [{
                "id": "u_2",
                "display_name": "Sam",
                "shared_tag": "running",
                "relationship": "liked"
              }]
            },
            { "type": "unknown" }
          ],
          "all_communities": []
        }
        """
        let dto = try JSONDecoder().decode(CommunityTabFeedResponseDTO.self, from: Data(json.utf8))
        let experience = CommunityDTOMapper.tabExperience(from: dto)
        #expect(experience.joinedCommunities.count == 1)
        #expect(experience.feedItems.count == 2)
    }

    @Test func communityDetailAndMemberMapping() throws {
        let detailJSON = """
        {
          "id": "c_2",
          "name": "Hikers",
          "member_count": 5,
          "activity_count": 1,
          "has_new_posts": false,
          "is_joined": true
        }
        """
        let detailDTO = try JSONDecoder().decode(CommunityDetailDTO.self, from: Data(detailJSON.utf8))
        let detail = CommunityDTOMapper.communityDetail(from: detailDTO)
        #expect(detail.isJoined)

        let memberJSON = """
        {
          "id": "u_3",
          "display_name": "Guest",
          "relationship_to_viewer": "shared_activity"
        }
        """
        let memberDTO = try JSONDecoder().decode(CommunityMemberDTO.self, from: Data(memberJSON.utf8))
        let member = CommunityDTOMapper.member(from: memberDTO)
        #expect(member.displayName == "Guest")

        let linked = CommunityDTOMapper.linkedActivity(
            from: CommunityLinkedActivityDTO(id: "act_1", title: "Hike", scheduleLine: "Sat 9am")
        )
        #expect(linked.title == "Hike")
    }

    @Test func likeResultMapsFromDTO() throws {
        let json = """
        { "liked": true, "like_count": 12 }
        """
        let dto = try JSONDecoder().decode(CommunityPostLikeResponseDTO.self, from: Data(json.utf8))
        let result = CommunityDTOMapper.likeResult(from: dto)
        #expect(result.viewerHasLiked)
        #expect(result.likeCount == 12)
    }
}
