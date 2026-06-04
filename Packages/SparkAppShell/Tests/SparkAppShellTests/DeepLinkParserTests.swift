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
}
