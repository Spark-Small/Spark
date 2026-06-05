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

    @Test func parseLikesTabDeepLink() {
        let url = URL(string: "spark://likes")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .tab(.likes, query: nil))
    }

    @Test func parseUniversalLikesTabLink() {
        let url = URL(string: "https://spark.app/tab/likes")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .tab(.likes, query: nil))
    }

    @Test func parseLikesInboundDeepLink() {
        let url = URL(string: "spark://likes/inbound")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .likesInbound)
    }

    @Test func parseUniversalLikesInboundLink() {
        let url = URL(string: "https://spark.app/tab/likes/inbound")!
        let route = DeepLinkParser.parse(url: url)
        #expect(route == .likesInbound)
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
}
