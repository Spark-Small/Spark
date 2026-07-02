// Module: SparkAppShellTests

import Foundation
import SparkAppShell
import Testing

struct DeepLinkParserTests {
    @Test func parseMessagesThreadDeepLink() {
        let url = URL(string: "spark://messages/thread/th_mock_001")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .conversation(threadID: "th_mock_001"))
    }

    @Test func parseMessagesTabDeepLink() {
        let url = URL(string: "spark://messages")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .tab(.messages, query: nil))
    }

    @Test func parseCommunityPostDeepLink() {
        let url = URL(string: "spark://community/post/cp_2")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .communityPost(postID: "cp_2"))
    }

    @Test func parseUniversalActivityLink() {
        let url = URL(string: "https://spark.app/a/act_42")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .activityDetail(activityID: "act_42"))
    }

    @Test func legacyLikesDeepLinkRoutesToCommunity() {
        let url = URL(string: "spark://likes")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .tab(.community, query: nil))
    }

    @Test func legacyUniversalLikesTabRoutesToCommunity() {
        let url = URL(string: "https://spark.app/tab/likes")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .tab(.community, query: nil))
    }

    @Test func legacyLikesInboundRoutesToCommunity() {
        let url = URL(string: "spark://likes/inbound")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .tab(.community, query: nil))
    }

    @Test func parseUniversalActivitiesPath() {
        let url = URL(string: "https://spark.app/activities/act_001")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .activityDetail(activityID: "act_001"))
    }

    @Test func parseUniversalMatchConversation() {
        let url = URL(string: "https://spark.app/matches/th_dm_001")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .conversation(threadID: "th_dm_001"))
    }

    @Test func parseUniversalCommunityPost() {
        let url = URL(string: "https://spark.app/community/posts/cp_001")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .communityPost(postID: "cp_001"))
    }

    @Test func parseBuddyTabDeepLink() {
        let url = URL(string: "spark://buddy")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .tab(.buddy, query: nil))
    }

    @Test func parseBuddyDetailCustomSchemeDeepLink() {
        let url = URL(string: "spark://buddy/buddy_city_1")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .buddyDetail(listingID: "buddy_city_1"))
    }

    @Test func parseBuddyDetailUniversalLink() {
        let url = URL(string: "https://spark.app/buddies/buddy_city_1")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .buddyDetail(listingID: "buddy_city_1"))
    }

    @Test func legacySearchDeepLinkRoutesToProfile() {
        let url = URL(string: "spark://search?q=coffee")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .tab(.profile, query: "coffee"))
    }

    @Test func legacyUniversalSearchTabRoutesToProfile() {
        let url = URL(string: "https://spark.app/tab/search?q=tea")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .tab(.profile, query: "tea"))
    }
}
