//
//  CommunityFeedFilter.swift
//  坐标系
//
//  广场浏览筛选（系统 glass 横滑 chip）；纯函数委托 Domain。
//  对用户顺序：全部 → 关注 → 发现作者 → 热议 → 与我相关（种草主职，非社交 Inbox）。
//

import Foundation
import CoordinateDomain
import CoordinateModels

enum CommunityFeedFilter: String, CaseIterable, Identifiable, Hashable, Sendable {
    case all
    case following
    /// 发现未关注作者（UI：发现作者）。
    case peopleYouFollow
    case conversation
    case mention

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: CommunityBrowseCopy.filterAll
        case .following: CommunityBrowseCopy.filterFollowing
        case .peopleYouFollow: CommunityBrowseCopy.filterPeopleYouFollow
        case .conversation: CommunityBrowseCopy.filterConversation
        case .mention: CommunityBrowseCopy.filterMention
        }
    }

    /// 同档 fill / 多色友好符号，避免 badge 变体贴导致视觉大小不一。
    var systemImage: String {
        switch self {
        case .all: "square.grid.2x2.fill"
        case .following: "person.2.fill"
        case .peopleYouFollow: "person.crop.circle.badge.plus"
        case .conversation: "bubble.left.and.bubble.right.fill"
        case .mention: "flag.checkered"
        }
    }

    /// VoiceOver：选中 chip 时补充筛选含义（标题仍是短标签）。
    var accessibilityHint: String {
        switch self {
        case .all: CommunityBrowseCopy.filterAllHint
        case .following: CommunityBrowseCopy.filterFollowingHint
        case .peopleYouFollow: CommunityBrowseCopy.filterPeopleYouFollowHint
        case .conversation: CommunityBrowseCopy.filterConversationHint
        case .mention: CommunityBrowseCopy.filterMentionHint
        }
    }

    var domainKind: CommunityBrowseFilterKind {
        switch self {
        case .all: .all
        case .following: .following
        case .peopleYouFollow: .peopleYouFollow
        case .conversation: .conversation
        case .mention: .mention
        }
    }
}

enum CommunityFeedFiltering {
    static func posts(
        _ posts: [CommunityPost],
        filter: CommunityFeedFilter,
        followedUserNames: Set<String>,
        currentUserName: String,
        joinedActivityTitles: Set<String>,
        retainedAuthorNames: Set<String> = []
    ) -> [CommunityPost] {
        CommunityBrowseFiltering.posts(
            posts,
            filter: filter.domainKind,
            followedUserNames: followedUserNames,
            currentUserName: currentUserName,
            joinedActivityTitles: joinedActivityTitles,
            retainedAuthorNames: retainedAuthorNames
        )
    }

    static func recommendedPost(
        from posts: [CommunityPost],
        currentUserName: String,
        followedUserNames: Set<String>
    ) -> CommunityPost? {
        CommunityBrowseFiltering.recommendedPost(
            from: posts,
            currentUserName: currentUserName,
            followedUserNames: followedUserNames
        )
    }
}
