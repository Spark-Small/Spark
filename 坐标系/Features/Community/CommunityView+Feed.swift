//
//  CommunityView+Feed.swift
//  坐标系
//
//  主 Feed 筛选与空态（发现作者关注：会话保留，见 retainedAuthorNames）。
//

import SwiftUI
import CoordinateModels

extension CommunityFeedStack {
    var joinedActivityTitles: Set<String> {
        Set(
            activities.joinedActivities.map(\.title)
            + activities.hostedActivities.map(\.title)
        )
    }

    var filteredPosts: [CommunityPost] {
        // 「发现作者」= 未关注作者；本会话刚关注的作者经 `sessionRetainedDiscoverAuthors` 保留至离档。
        var posts = CommunityFeedFiltering.posts(
            model.items,
            filter: feedFilter,
            followedUserNames: app.followedUserNames,
            currentUserName: model.currentUserName,
            joinedActivityTitles: joinedActivityTitles,
            retainedAuthorNames: feedFilter == .peopleYouFollow
                ? sessionRetainedDiscoverAuthors
                : []
        )
        if shouldPinRecommended, let recommended = recommendedPost {
            posts = posts.filter { $0.id != recommended.id }
        }
        return posts
    }

    /// 整页空态（筛选下 Scroll 内嵌随滚）；有帖时只渲染行。
    var showsFeedUnavailable: Bool {
        if model.loadErrorMessage != nil, model.items.isEmpty { return true }
        if model.items.isEmpty { return true }
        return filteredPosts.isEmpty
    }

    @ViewBuilder
    var feedUnavailableContent: some View {
        if let error = model.loadErrorMessage, model.items.isEmpty {
            errorState(message: error)
        } else if model.items.isEmpty {
            emptyState
        } else {
            filterEmptyState(for: feedFilter)
        }
    }

    @ViewBuilder
    var feedPostsSection: some View {
        ForEach(filteredPosts) { post in
            CommunityFeedPostRow(
                post: post,
                isLiked: model.isLiked(post.id),
                isBookmarked: model.isBookmarked(post.id),
                isReposted: model.isReposted(post.id),
                isFollowingAuthor: app.isFollowing(post.author)
            )
            .equatable()
            .communityFeedRowChrome()
        }
    }

    @ViewBuilder
    func filterEmptyState(for filter: CommunityFeedFilter) -> some View {
        switch filter {
        case .following:
            followingEmptyState
        case .peopleYouFollow:
            discoverAuthorsEmptyState
        case .conversation:
            conversationEmptyState
        case .mention:
            mentionEmptyState
        case .all:
            filteredEmptyState
        }
    }

    var emptyState: some View {
        ContentUnavailableView {
            Label(CommunityBrowseCopy.emptyTitle, systemImage: "photo.on.rectangle")
        } description: {
            Text(CommunityBrowseCopy.emptyDescription)
        } actions: {
            Button(CommunityBrowseCopy.composeAccessibility) { model.presentation.beginCompose() }
        }
    }

    var followingEmptyState: some View {
        ContentUnavailableView {
            Label(CommunityBrowseCopy.feedEmptyFollowing, systemImage: "person.crop.circle.badge.plus")
        } description: {
            Text(CommunityBrowseCopy.feedEmptyFollowingHint)
        } actions: {
            Button(CommunityBrowseCopy.feedEmptyFollowingAction) {
                feedFilter = .peopleYouFollow
            }
        }
    }

    var discoverAuthorsEmptyState: some View {
        ContentUnavailableView {
            Label(CommunityBrowseCopy.feedEmptyDiscover, systemImage: "person.crop.circle.badge.plus")
        } description: {
            Text(CommunityBrowseCopy.feedEmptyDiscoverHint)
        } actions: {
            Button(CommunityBrowseCopy.feedEmptyDiscoverAction) {
                feedFilter = .all
            }
        }
    }

    var conversationEmptyState: some View {
        ContentUnavailableView {
            Label(CommunityBrowseCopy.feedEmptyConversation, systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text(CommunityBrowseCopy.feedEmptyConversationHint)
        } actions: {
            Button(CommunityBrowseCopy.feedEmptyConversationAction) {
                feedFilter = .all
            }
        }
    }

    var mentionEmptyState: some View {
        ContentUnavailableView {
            Label(CommunityBrowseCopy.feedEmptyMention, systemImage: "flag.checkered")
        } description: {
            Text(CommunityBrowseCopy.feedEmptyMentionHint)
        } actions: {
            Button(CommunityBrowseCopy.feedEmptyMentionAction) {
                feedFilter = .all
            }
        }
    }

    var filteredEmptyState: some View {
        ContentUnavailableView {
            Label(CommunityBrowseCopy.feedEmptyFiltered, systemImage: "line.3.horizontal.decrease.circle")
        } description: {
            Text(CommunityBrowseCopy.feedEmptyFilteredHint)
        }
    }

    func errorState(message: String) -> some View {
        ContentUnavailableView {
            Label(CommunityBrowseCopy.loadFailedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button(CommunityBrowseCopy.retryLoad) {
                Task { await model.reloadFromRepository() }
            }
        }
    }
}
