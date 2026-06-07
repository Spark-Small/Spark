// Module: SparkCommunity — Home feed relevance for Plan A (joined + familiar content only).

import Foundation

enum CommunityFeedRelevance {
    /// Posts and items shown on the community tab home feed.
    static func homeFeedItems(
        from items: [CommunityFeedItem],
        joinedCommunities: [CommunitySummary]
    ) -> [CommunityFeedItem] {
        let joinedNames = Set(joinedCommunities.map(\.name))
        return items.compactMap { item in
            switch item {
            case .peopleDiscovery:
                nil
            case .post(let post):
                isRelevantHomePost(post, joinedNames: joinedNames) ? .post(post) : nil
            }
        }
    }

    static func discoverableCommunities(
        all: [CommunitySummary],
        joined: [CommunitySummary]
    ) -> [CommunitySummary] {
        let joinedIDs = Set(joined.map(\.id))
        return all.filter { !joinedIDs.contains($0.id) }
    }

    static func isRelevantHomePost(
        _ post: CommunityFeedPost,
        joinedNames: Set<String>
    ) -> Bool {
        if post.kind == .activityRecap { return true }
        if post.sharedActivityWithViewer != nil { return true }
        if post.relationshipToViewer != .none { return true }
        if joinedNames.contains(post.communityName) { return true }
        // REASONING: Viewer-authored posts must appear immediately after publish.
        if post.authorUserID == "viewer" { return true }
        return false
    }
}
