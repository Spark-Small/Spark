// Module: SparkCommunity — Home feed relevance for Plan A (joined + familiar content only).

import Foundation

enum CommunityFeedRelevance {
    /// Posts and items shown on the community tab home feed.
    static func homeFeedItems(
        from items: [CommunityFeedItem],
        joinedCommunities: [CommunitySummary]
    ) -> [CommunityFeedItem] {
        let joinedNames = Set(joinedCommunities.map(\.name))
        let filtered = items.compactMap { item -> CommunityFeedItem? in
            switch item {
            case .peopleDiscovery:
                return nil
            case .post(let post):
                return isRelevantHomePost(post, joinedNames: joinedNames) ? .post(post) : nil
            }
        }
        return sortedHomeFeedItems(filtered)
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

    private static func sortedHomeFeedItems(_ items: [CommunityFeedItem]) -> [CommunityFeedItem] {
        items.sorted { lhs, rhs in
            guard case .post(let left) = lhs, case .post(let right) = rhs else {
                return false
            }
            let leftScore = homeFeedSortScore(left)
            let rightScore = homeFeedSortScore(right)
            if leftScore != rightScore { return leftScore > rightScore }
            return left.createdAt > right.createdAt
        }
    }

    private static func homeFeedSortScore(_ post: CommunityFeedPost) -> Int {
        var score = 0
        if post.kind == .activityRecap, post.linkedActivity != nil {
            score += 200
        } else if post.linkedActivity != nil {
            score += 100
        }
        if post.sharedActivityWithViewer != nil {
            score += 50
        }
        // REASONING: Social proof nudges recap readers toward Activity CTA without outranking relevance tier.
        score += min(post.likeCount, 20)
        return score
    }
}
