// Module: SparkCommunityTests — Home feed relevance filtering.

@testable import SparkCommunity
import Foundation
import Testing

struct CommunityFeedRelevanceTests {
    @Test func homeFeedItemsDropsPeopleDiscovery() {
        let person = DiscoveredPerson(
            id: "u_1",
            displayName: "Test",
            sharedTag: "爬山",
            relationship: .liked
        )
        let post = samplePost(communityName: "爬山队")
        let items: [CommunityFeedItem] = [
            .post(post),
            .peopleDiscovery([person])
        ]
        let joined = [CommunitySummary(id: "cm_hike", name: "爬山队", memberCount: 1, activityCount: 1)]
        let filtered = CommunityFeedRelevance.homeFeedItems(from: items, joinedCommunities: joined)
        #expect(filtered.count == 1)
        if case .post = filtered[0] {
        } else {
            Issue.record("Expected post item")
        }
    }

    @Test func homeFeedItemsKeepsJoinedRecapAndSharedActivity() {
        let joined = [CommunitySummary(id: "cm_book", name: "读书会", memberCount: 1, activityCount: 1)]
        let recap = samplePost(communityName: "其他", kind: .activityRecap)
        let shared = CommunityFeedPost(
            id: "cp_shared",
            authorDisplayName: "A",
            authorUserID: "u_a",
            communityName: "陌生社区",
            content: "Body",
            likeCount: 1,
            commentCount: 0,
            createdAt: Date(),
            sharedActivityWithViewer: SharedActivityContext(id: "act_1", name: "Coffee")
        )
        let unrelated = samplePost(communityName: "未加入")
        let items: [CommunityFeedItem] = [
            .post(recap),
            .post(shared),
            .post(unrelated)
        ]
        let filtered = CommunityFeedRelevance.homeFeedItems(from: items, joinedCommunities: joined)
        #expect(filtered.count == 2)
    }

    @Test func discoverableCommunitiesExcludesJoined() {
        let joined = CommunitySummary(id: "cm_hike", name: "爬山队", memberCount: 1, activityCount: 1)
        let discoverable = CommunitySummary(id: "cm_run", name: "晨跑打卡", memberCount: 2, activityCount: 2)
        let result = CommunityFeedRelevance.discoverableCommunities(
            all: [joined, discoverable],
            joined: [joined]
        )
        #expect(result == [discoverable])
    }

    @Test func homeFeedItemsPrioritizesLinkedRecapPosts() {
        let joined = [CommunitySummary(id: "cm_book", name: "读书会", memberCount: 1, activityCount: 1)]
        let olderRecap = CommunityFeedPost(
            id: "cp_recap_old",
            authorDisplayName: "A",
            authorUserID: "u_a",
            communityName: "读书会",
            content: "Recap",
            likeCount: 1,
            commentCount: 0,
            createdAt: Date().addingTimeInterval(-86_400),
            linkedActivity: LinkedActivityContext(id: "act_1", name: "Coffee"),
            kind: .activityRecap
        )
        let newerDiscussion = samplePost(communityName: "读书会")
        let items: [CommunityFeedItem] = [
            .post(newerDiscussion),
            .post(olderRecap)
        ]
        let filtered = CommunityFeedRelevance.homeFeedItems(from: items, joinedCommunities: joined)
        guard case .post(let first) = filtered.first else {
            Issue.record("Expected post item")
            return
        }
        #expect(first.id == "cp_recap_old")
    }

    @Test func homeFeedItemsPrioritizesHigherEngagementWithinRecapTier() {
        let joined = [CommunitySummary(id: "cm_book", name: "读书会", memberCount: 1, activityCount: 1)]
        let lowEngagementRecap = CommunityFeedPost(
            id: "cp_recap_low",
            authorDisplayName: "A",
            authorUserID: "u_a",
            communityName: "读书会",
            content: "Recap",
            likeCount: 1,
            commentCount: 0,
            createdAt: Date(),
            linkedActivity: LinkedActivityContext(id: "act_1", name: "Coffee"),
            kind: .activityRecap
        )
        let highEngagementRecap = CommunityFeedPost(
            id: "cp_recap_high",
            authorDisplayName: "B",
            authorUserID: "u_b",
            communityName: "读书会",
            content: "Recap",
            likeCount: 18,
            commentCount: 0,
            createdAt: Date().addingTimeInterval(-86_400),
            linkedActivity: LinkedActivityContext(id: "act_2", name: "Hike"),
            kind: .activityRecap
        )
        let items: [CommunityFeedItem] = [
            .post(lowEngagementRecap),
            .post(highEngagementRecap)
        ]
        let filtered = CommunityFeedRelevance.homeFeedItems(from: items, joinedCommunities: joined)
        guard case .post(let first) = filtered.first else {
            Issue.record("Expected post item")
            return
        }
        #expect(first.id == "cp_recap_high")
    }

    private func samplePost(
        communityName: String,
        kind: CommunityPostKind = .discussion
    ) -> CommunityFeedPost {
        CommunityFeedPost(
            id: "cp_test",
            authorDisplayName: "Author",
            authorUserID: "u_test",
            communityName: communityName,
            content: "Body",
            likeCount: 0,
            commentCount: 0,
            createdAt: Date(),
            kind: kind
        )
    }
}
