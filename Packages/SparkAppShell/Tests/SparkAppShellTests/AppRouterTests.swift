// Module: SparkAppShellTests

import Foundation
import SparkAppShell
import SparkPayments
import Testing

@MainActor
struct AppRouterTests {
    @Test func deepLinkToMessagesWhenGuestShowsAuthSheet() {
        let router = AppRouter()
        let url = URL(string: "spark://messages")!
        router.handle(url: url, isAuthenticated: false)
        #expect(router.globalSheet == .authRequired)
        #expect(router.pendingDeepLinkAfterAuth != nil)
        #expect(router.selectedTab == .community)
    }

    @Test func deepLinkAppliesWhenAuthenticated() {
        let router = AppRouter()
        router.handle(url: URL(string: "spark://community")!, isAuthenticated: true)
        #expect(router.selectedTab == .community)
        #expect(router.globalSheet == nil)
    }

    @Test func paywallDeepLinkWhenAuthenticated() {
        let router = AppRouter()
        router.handle(url: URL(string: "spark://paywall?placement=activity")!, isAuthenticated: true)
        #expect(router.globalFullScreenCover == .paywall(placement: .activity))
    }

    @Test func openConversationSelectsMessagesTab() {
        let router = AppRouter()
        router.openConversation(threadID: "th_mock_001")
        #expect(router.selectedTab == .messages)
        #expect(router.pendingConversationThreadID == "th_mock_001")
    }

    @Test func conversationDeepLinkWhenAuthenticated() {
        let router = AppRouter()
        let url = URL(string: "spark://messages/thread/th_mock_002")!
        router.handle(url: url, isAuthenticated: true)
        #expect(router.selectedTab == .messages)
        #expect(router.pendingConversationThreadID == "th_mock_002")
    }

    @Test func openCommunityPostSelectsCommunityTab() {
        let router = AppRouter()
        router.openCommunityPost(postID: "cp_1")
        #expect(router.selectedTab == .community)
        #expect(router.pendingCommunityPostID == "cp_1")
    }

    @Test func communityPostDeepLinkWhenAuthenticated() {
        let router = AppRouter()
        router.handle(url: URL(string: "spark://community/post/cp_3")!, isAuthenticated: true)
        #expect(router.selectedTab == .community)
        #expect(router.pendingCommunityPostID == "cp_3")
    }

    @Test func openActivityDetailSelectsActivityTab() {
        let router = AppRouter()
        router.openActivityDetail(activityID: "act_1")
        #expect(router.selectedTab == .activity)
        #expect(router.pendingActivityID == "act_1")
    }

    @Test func activityUniversalLinkWhenAuthenticated() {
        let router = AppRouter()
        router.handle(url: URL(string: "https://spark.app/a/act_9")!, isAuthenticated: true)
        #expect(router.selectedTab == .activity)
        #expect(router.pendingActivityID == "act_9")
    }
}
