// Module: SparkAppShellTests

import Foundation
import SparkActivity
import SparkAppShell
import SparkPayments
import Testing

@MainActor
struct AppRouterTests {
    @Test func defaultSelectedTabIsActivity() {
        let router = AppRouter()
        #expect(router.selectedTab == .activity)
    }

    @Test func deepLinkToMessagesWhenGuestShowsAuthSheet() {
        let router = AppRouter()
        let url = URL(string: "spark://messages")!
        router.handle(url: url, isAuthenticated: false)
        #expect(router.globalSheet == .authRequired)
        #expect(router.globalFullScreenCover == nil)
        #expect(router.pendingDeepLinkAfterAuth != nil)
        #expect(router.selectedTab == .activity)
    }

    @Test func finishAuthenticationLandsOnActivityWithoutDeepLink() {
        let router = AppRouter()
        router.selectedTab = .messages
        router.globalSheet = .authRequired
        router.finishAuthentication()
        #expect(router.selectedTab == .activity)
        #expect(router.globalSheet == nil)
        #expect(router.pendingDeepLinkAfterAuth == nil)
    }

    @Test func finishAuthenticationAppliesPendingDeepLink() {
        let router = AppRouter()
        router.pendingDeepLinkAfterAuth = .tab(.community, query: nil)
        router.globalSheet = .authRequired
        router.finishAuthentication()
        #expect(router.selectedTab == .community)
        #expect(router.globalSheet == nil)
        #expect(router.pendingDeepLinkAfterAuth == nil)
    }

    @Test func resetAfterSignOutReturnsToActivityTab() {
        let router = AppRouter()
        router.selectedTab = .messages
        router.pendingDeepLinkAfterAuth = .tab(.messages, query: nil)
        router.resetAfterSignOut()
        #expect(router.selectedTab == .activity)
        #expect(router.pendingDeepLinkAfterAuth == nil)
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
        router.openActivityDetail(activityID: "act_1", context: .discover)
        #expect(router.selectedTab == .activity)
        #expect(router.pendingActivityID == "act_1")
        #expect(router.pendingActivityDetailContext == .discover)
    }

    @Test func activityUniversalLinkSetsExternalEntryContext() {
        let router = AppRouter()
        router.handle(url: URL(string: "https://spark.app/a/act_9")!, isAuthenticated: false)
        #expect(router.pendingActivityDetailContext == .externalEntry)
    }

    @Test func activityUniversalLinkWhenGuestOpensWithoutAuthSheet() {
        let router = AppRouter()
        router.handle(url: URL(string: "https://spark.app/a/act_9")!, isAuthenticated: false)
        #expect(router.globalSheet == nil)
        #expect(router.selectedTab == .activity)
        #expect(router.pendingActivityID == "act_9")
    }

    @Test func communityPostDeepLinkWhenGuestOpensWithoutAuthSheet() {
        let router = AppRouter()
        router.handle(url: URL(string: "spark://community/post/cp_3")!, isAuthenticated: false)
        #expect(router.globalSheet == nil)
        #expect(router.selectedTab == .community)
        #expect(router.pendingCommunityPostID == "cp_3")
    }

    @Test func activityUniversalLinkWhenAuthenticated() {
        let router = AppRouter()
        router.handle(url: URL(string: "https://spark.app/a/act_9")!, isAuthenticated: true)
        #expect(router.selectedTab == .activity)
        #expect(router.pendingActivityID == "act_9")
    }

    @Test func cancelAuthPresentationPreservesCreateDraft() {
        let router = AppRouter()
        let draft = CreateActivityDraft(title: "Coffee")
        router.requireSignInForCreateActivity(draft: draft)
        router.cancelAuthPresentation()
        #expect(router.pendingCreateActivityDraft?.title == "Coffee")
        #expect(router.pendingDeepLinkAfterAuth == nil)
        #expect(router.globalSheet == nil)
    }

    @Test func requireSignInForBrowseJoinQueuesJoinSheet() {
        let router = AppRouter()
        router.requireSignInForBrowseJoin(activityID: "act_1")
        #expect(router.pendingBrowseJoinActivityID == "act_1")
        #expect(router.pendingDeepLinkAfterAuth == .tab(.activity, query: nil))
        #expect(router.globalSheet == .authRequired)
    }

    @Test func cancelAuthPresentationClearsPendingBrowseJoin() {
        let router = AppRouter()
        router.requireSignInForBrowseJoin(activityID: "act_1")
        router.cancelAuthPresentation()
        #expect(router.pendingBrowseJoinActivityID == nil)
    }

    @Test func openActivityDetailHonorsPreferredTab() {
        let router = AppRouter()
        router.selectedTab = .messages
        router.openActivityDetail(activityID: "act_2", context: .discover, preferredTab: .messages)
        #expect(router.selectedTab == .messages)
        #expect(router.pendingActivityID == "act_2")
    }

    @Test func openBuddyDetailSelectsBuddyTab() {
        let router = AppRouter()
        router.openBuddyDetail(listingID: "buddy_city_1")
        #expect(router.selectedTab == .buddy)
        #expect(router.pendingBuddyListingID == "buddy_city_1")
    }

    @Test func buddyDetailDeepLinkWhenAuthenticated() {
        let router = AppRouter()
        router.handle(url: URL(string: "spark://buddy/buddy_city_1")!, isAuthenticated: true)
        #expect(router.selectedTab == .buddy)
        #expect(router.pendingBuddyListingID == "buddy_city_1")
    }

    @Test func resetAfterSignOutClearsBuddyPendingNavigation() {
        let router = AppRouter()
        router.selectedTab = .buddy
        router.pendingBuddyListingID = "buddy_city_1"
        router.resetAfterSignOut()
        #expect(router.selectedTab == .activity)
        #expect(router.pendingBuddyListingID == nil)
    }
}
