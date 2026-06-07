// Module: SparkCommunity — Root navigation and iPad split helpers.

import SwiftUI

enum CommunitySplitDestination: Hashable {
    case post(String)
    case community(String)
}

extension CommunityRootView {
    var usesSplitLayout: Bool {
        horizontalSizeClass == .regular
    }

    func openPost(_ post: CommunityPost) {
        openPostID(post.id)
    }

    func openFeedPost(_ post: CommunityFeedPost) {
        openPostID(post.id)
    }

    func openPostID(_ postID: String) {
        if usesSplitLayout {
            splitDestination = .post(postID)
        } else {
            navigationPath.append(postID)
        }
    }

    func openCommunity(_ community: CommunitySummary) {
        if usesSplitLayout {
            splitDestination = .community(community.id)
        } else {
            navigationPath.append(community)
        }
    }

    @ViewBuilder
    var splitDetail: some View {
        switch splitDestination {
        case .post(let postID):
            postDetailView(postID: postID)
        case .community(let communityID):
            CommunityDetailView(
                viewModel: coordinator.makeDetailViewModel(communityID: communityID),
                likedPersonIDs: viewModel.likedPersonIDs,
                onOpenActivity: onOpenLinkedActivity,
                onOpenPost: { openFeedPost($0) },
                onLikePerson: likePerson
            )
        case nil:
            ContentUnavailableView {
                Label(
                    String(
                        localized: "community.split.empty.title",
                        defaultValue: "选择内容",
                        comment: "Split community placeholder"
                    ),
                    systemImage: "person.2"
                )
            } description: {
                Text(
                    String(
                        localized: "community.split.empty.subtitle",
                        defaultValue: "从左侧打开帖子或社区",
                        comment: "Split community hint"
                    )
                )
            }
        }
    }
}
