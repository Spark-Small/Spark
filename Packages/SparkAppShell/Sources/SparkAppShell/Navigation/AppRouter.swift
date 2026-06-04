// Module: SparkAppShell — Central navigation and global presentation state.

import Foundation
import Observation
import SparkPayments

@MainActor
@Observable
public final class AppRouter {
    public var selectedTab: SparkTab
    public var pendingSearchQuery: String?
    public var pendingDeepLinkAfterAuth: DeepLinkRoute?
    /// Thread to open on the Messages tab after inbox is ready (consumed by `MessagesRootView`).
    public var pendingConversationThreadID: String?
    /// Post to push on the Community tab after the feed loads (consumed by `CommunityRootView`).
    public var pendingCommunityPostID: String?
    /// Activity recap draft for Community tab (Phase 24).
    public var pendingCommunityRecapActivityID: String?
    /// Activity to push on the Activity tab (consumed by `ActivityRootView`).
    public var pendingActivityID: String?
    public var pendingLikesInbound = false
    public var globalSheet: GlobalPresentation?
    public var globalFullScreenCover: GlobalPresentation?

    public init(selectedTab: SparkTab = .community) {
        self.selectedTab = selectedTab
    }

    public func handle(url: URL, isAuthenticated: Bool) {
        guard let route = DeepLinkParser.parse(url: url) else { return }
        handle(route: route, isAuthenticated: isAuthenticated)
    }

    public func handle(route: DeepLinkRoute, isAuthenticated: Bool) {
        switch route {
        case let .tab(tab, _):
            if tab.requiresAuthentication, !isAuthenticated {
                pendingDeepLinkAfterAuth = route
                presentAuthRequired()
                return
            }
        case .paywall, .conversation, .communityPost, .communityRecap, .activityDetail, .likesInbound:
            if !isAuthenticated {
                pendingDeepLinkAfterAuth = route
                presentAuthRequired()
                return
            }
        }
        apply(route)
    }

    public func apply(_ route: DeepLinkRoute) {
        switch route {
        case let .tab(tab, query):
            selectedTab = tab
            if tab == .search, let query, !query.isEmpty {
                pendingSearchQuery = query
            }
        case let .paywall(placement):
            globalFullScreenCover = .paywall(placement: placement)
        case let .conversation(threadID):
            openConversation(threadID: threadID)
        case let .communityPost(postID):
            openCommunityPost(postID: postID)
        case let .communityRecap(activityID):
            openCommunityRecap(activityID: activityID)
        case let .activityDetail(activityID):
            openActivityDetail(activityID: activityID)
        case .likesInbound:
            openLikesInbound()
        }
    }

    public func openLikesInbound() {
        selectedTab = .likes
        pendingLikesInbound = true
    }

    /// Opens activity detail on the Activity tab (universal links, search, inbox).
    public func openActivityDetail(activityID: String, preferredTab: SparkTab = .activity) {
        selectedTab = preferredTab
        switch preferredTab {
        case .activity:
            pendingActivityID = activityID
        case .likes, .community, .messages, .search:
            pendingActivityID = activityID
            selectedTab = .activity
        }
    }

    /// Switches to Community and queues a post push once the feed is loaded.
    public func openCommunityPost(postID: String) {
        selectedTab = .community
        pendingCommunityPostID = postID
    }

    public func clearPendingCommunityPost() {
        pendingCommunityPostID = nil
    }

    public func openCommunityRecap(activityID: String) {
        selectedTab = .community
        pendingCommunityRecapActivityID = activityID
    }

    public func clearPendingCommunityRecap() {
        pendingCommunityRecapActivityID = nil
    }

    /// Switches to Messages and queues a thread push once the inbox is loaded.
    public func openConversation(threadID: String) {
        selectedTab = .messages
        pendingConversationThreadID = threadID
    }

    public func clearPendingConversation() {
        pendingConversationThreadID = nil
    }

    public func presentPaywall(placement: PaywallPlacement) {
        globalFullScreenCover = .paywall(placement: placement)
    }

    public func selectTab(_ tab: SparkTab, isAuthenticated: Bool) -> Bool {
        if tab.requiresAuthentication, !isAuthenticated {
            presentAuthRequired()
            return false
        }
        selectedTab = tab
        return true
    }

    public func presentAuthRequired() {
        globalSheet = .authRequired
    }

    public func presentInfo(title: String, message: String) {
        globalFullScreenCover = .info(title: title, message: message)
    }

    public func dismissGlobalPresentation() {
        globalSheet = nil
        globalFullScreenCover = nil
    }

    public func resetAfterSignOut() {
        selectedTab = .community
        pendingSearchQuery = nil
        pendingConversationThreadID = nil
        pendingCommunityPostID = nil
        pendingCommunityRecapActivityID = nil
        pendingActivityID = nil
        pendingLikesInbound = false
        dismissGlobalPresentation()
    }
}
