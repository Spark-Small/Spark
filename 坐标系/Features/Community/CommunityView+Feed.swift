//
//  CommunityView+Feed.swift
//  坐标系
//
//  主 Feed 筛选与空态（搜索建议见 +Search）。
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
        // 「发现作者」= 未关注作者的内容筛选；点关注后该作者帖诚实离开本档（进「关注」）。
        var posts = CommunityFeedFiltering.posts(
            model.items,
            filter: feedFilter,
            followedUserNames: app.followedUserNames,
            currentUserName: model.currentUserName,
            joinedActivityTitles: joinedActivityTitles
        )
        if shouldPinRecommended, let recommended = recommendedPost {
            posts = posts.filter { $0.id != recommended.id }
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return posts }
        return posts.filter { post in
            post.messageText.localizedCaseInsensitiveContains(query)
                || post.author.localizedCaseInsensitiveContains(query)
                || post.title.localizedCaseInsensitiveContains(query)
                || post.tags.contains { $0.localizedCaseInsensitiveContains(query) }
                || (post.relatedActivityTitle?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    @ViewBuilder
    var feedPostsSection: some View {
        Group {
            if let error = model.loadErrorMessage, model.items.isEmpty {
                errorState(message: error)
                    .communityFeedRowChrome()
            } else if model.items.isEmpty {
                emptyState
                    .communityFeedRowChrome()
            } else if filteredPosts.isEmpty {
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    searchEmptyState
                        .communityFeedRowChrome()
                } else {
                    filterEmptyState(for: feedFilter)
                        .communityFeedRowChrome()
                }
            } else {
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
                .activityPrimaryCTA(controlSize: .large)
        }
        .communityEmptyStateChrome()
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
            .activityPrimaryCTA(controlSize: .large)
        }
        .communityEmptyStateChrome()
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
            .activityPrimaryCTA(controlSize: .large)
        }
        .communityEmptyStateChrome()
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
            .activityPrimaryCTA(controlSize: .large)
        }
        .communityEmptyStateChrome()
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
            .activityPrimaryCTA(controlSize: .large)
        }
        .communityEmptyStateChrome()
    }

    var filteredEmptyState: some View {
        ContentUnavailableView {
            Label(CommunityBrowseCopy.feedEmptyFiltered, systemImage: "line.3.horizontal.decrease.circle")
        } description: {
            Text(CommunityBrowseCopy.feedEmptyFilteredHint)
        }
        .communityEmptyStateChrome()
    }

    var searchEmptyState: some View {
        ContentUnavailableView.search(text: searchText)
            .communityEmptyStateChrome()
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
            .activityPrimaryCTA(controlSize: .large)
        }
        .communityEmptyStateChrome()
    }
}
