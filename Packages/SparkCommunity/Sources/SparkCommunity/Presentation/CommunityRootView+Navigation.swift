// Module: SparkCommunity — Root navigation helpers.

import SwiftUI

extension CommunityRootView {
    func openPost(_ post: CommunityPost) {
        openPostID(post.id)
    }

    func openFeedPost(_ post: CommunityFeedPost) {
        openPostID(post.id)
    }

    func openPostID(_ postID: String) {
        navigationPath.append(postID)
    }

    func openCommunity(_ community: CommunitySummary) {
        navigationPath.append(community)
    }
}
