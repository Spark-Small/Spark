// Module: SparkAppShell — Tab routing helpers for SparkMainTabView.

import SparkSearch

enum SparkMainTabRouting {
    @MainActor
    static func handleSearchResult(_ item: SearchResultItem, router: AppRouter) {
        switch item.resultKind {
        case .community:
            router.openCommunityPost(postID: item.id)
        case .activity:
            router.openActivityDetail(activityID: item.id)
        case .person, .none:
            break
        }
    }

    static func peerUserID(fromDirectThreadID threadID: String) -> String {
        let prefix = "th_dm_"
        if threadID.hasPrefix(prefix) {
            return String(threadID.dropFirst(prefix.count))
        }
        return threadID
    }
}
