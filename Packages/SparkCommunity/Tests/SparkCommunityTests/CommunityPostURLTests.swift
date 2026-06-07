// Module: SparkCommunityTests — Share link helpers.

import Foundation
import SparkCommunity
import Testing

struct CommunityPostURLTests {
    @Test func deepLinkUsesSparkScheme() {
        let url = CommunityPostURL.deepLink(postID: "cp_1")
        #expect(url.absoluteString == "spark://community/post/cp_1")
    }

    @Test func universalLinkUsesWebBase() {
        let url = CommunityPostURL.universalLink(postID: "cp_2")
        #expect(url.absoluteString.contains("community/post/cp_2"))
    }

    @Test func shareLinkMatchesUniversalLink() {
        #expect(CommunityPostURL.shareLink(postID: "cp_3") == CommunityPostURL.universalLink(postID: "cp_3"))
    }

    @Test func recapDeepLinkIncludesActivityQuery() {
        let url = CommunityPostURL.recapDeepLink(activityID: "act_1")
        #expect(url.scheme == "spark")
        #expect(url.host == "community")
        #expect(url.query?.contains("activity_id=act_1") == true)
    }

    @Test func recapUniversalLinkIncludesActivityQuery() {
        let url = CommunityPostURL.recapUniversalLink(activityID: "act_2")
        #expect(url.absoluteString.contains("community"))
        #expect(url.query?.contains("activity_id=act_2") == true)
    }
}
