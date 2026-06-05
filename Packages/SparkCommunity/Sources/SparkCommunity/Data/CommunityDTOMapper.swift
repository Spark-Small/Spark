// Module: SparkCommunity — DTO mapping.

import Foundation

enum CommunityDTOMapper {
    private static func parseISO8601(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) { return date }
        return ISO8601DateFormatter().date(from: raw)
    }

    static func post(from dto: CommunityPostDTO) -> CommunityPost {
        CommunityPost(
            id: dto.id,
            title: dto.title,
            excerpt: dto.excerpt,
            authorDisplayName: dto.authorDisplayName,
            replyCount: dto.replyCount
        )
    }

    static func postDetail(from dto: CommunityPostDetailDTO) -> CommunityPostDetail {
        CommunityPostDetail(
            id: dto.id,
            title: dto.title,
            body: dto.body,
            authorDisplayName: dto.authorDisplayName,
            authorUserID: dto.authorUserID,
            replyCount: dto.replyCount,
            replies: (dto.replies ?? []).map(reply),
            linkedActivity: dto.linkedActivity.map(linkedActivityContext)
        )
    }

    static func reply(from dto: CommunityPostReplyDTO) -> CommunityPostReply {
        CommunityPostReply(
            id: dto.id,
            body: dto.body,
            authorDisplayName: dto.authorDisplayName,
            createdAt: dto.createdAt.flatMap(parseISO8601)
        )
    }

    static func tabExperience(from dto: CommunityTabFeedResponseDTO) -> CommunityTabExperience {
        CommunityTabExperience(
            joinedCommunities: dto.joinedCommunities.map(summary),
            feedItems: dto.items.compactMap(feedItem),
            allCommunities: dto.allCommunities.map(summary)
        )
    }

    static func communityDetail(from dto: CommunityDetailDTO) -> CommunityDetail {
        CommunityDetail(summary: summary(from: dto), isJoined: dto.isJoined)
    }

    static func linkedActivity(from dto: CommunityLinkedActivityDTO) -> CommunityLinkedActivity {
        CommunityLinkedActivity(id: dto.id, title: dto.title, scheduleLine: dto.scheduleLine)
    }

    static func member(from dto: CommunityMemberDTO) -> CommunityMember {
        CommunityMember(
            id: dto.id,
            displayName: dto.displayName,
            avatarURL: dto.avatarURL.flatMap(URL.init(string:)),
            bio: dto.bio ?? "",
            relationship: relationship(from: dto.relationshipToViewer)
        )
    }

    private static func summary(from dto: CommunityDetailDTO) -> CommunitySummary {
        CommunitySummary(
            id: dto.id,
            name: dto.name,
            coverURL: dto.coverURL.flatMap(URL.init(string:)),
            memberCount: dto.memberCount,
            activityCount: dto.activityCount,
            hasNewPosts: dto.hasNewPosts,
            bio: dto.bio ?? ""
        )
    }

    private static func summary(from dto: CommunitySummaryDTO) -> CommunitySummary {
        CommunitySummary(
            id: dto.id,
            name: dto.name,
            coverURL: dto.coverURL.flatMap(URL.init(string:)),
            memberCount: dto.memberCount,
            activityCount: dto.activityCount,
            hasNewPosts: dto.hasNewPosts,
            bio: dto.bio ?? ""
        )
    }

    private static func feedItem(from dto: CommunityFeedItemDTO) -> CommunityFeedItem? {
        switch dto.type {
        case "post":
            guard let postDTO = dto.post else { return nil }
            return .post(feedPost(from: postDTO))
        case "people_discovery":
            guard let people = dto.people else { return nil }
            return .peopleDiscovery(people.map(discoveredPerson))
        default:
            return nil
        }
    }

    private static func feedPost(from dto: CommunityFeedPostDTO) -> CommunityFeedPost {
        CommunityFeedPost(
            id: dto.id,
            authorDisplayName: dto.authorDisplayName,
            authorUserID: dto.authorUserID,
            communityName: dto.communityName,
            content: dto.content,
            imageURL: dto.imageURL.flatMap(URL.init(string:)),
            likeCount: dto.likeCount,
            commentCount: dto.commentCount,
            tags: dto.tags ?? [],
            createdAt: parseISO8601(dto.createdAt) ?? Date(),
            sharedActivityWithViewer: dto.sharedActivityWithViewer.map(sharedActivity),
            relationshipToViewer: relationship(from: dto.relationshipToViewer),
            linkedActivity: dto.linkedActivity.map(linkedActivityContext)
        )
    }

    private static func discoveredPerson(from dto: DiscoveredPersonDTO) -> DiscoveredPerson {
        DiscoveredPerson(
            id: dto.id,
            displayName: dto.displayName,
            avatarURL: dto.avatarURL.flatMap(URL.init(string:)),
            sharedTag: dto.sharedTag,
            relationship: relationship(from: dto.relationship)
        )
    }

    private static func sharedActivity(from dto: SharedActivityDTO) -> SharedActivityContext {
        SharedActivityContext(id: dto.id, name: dto.name)
    }

    private static func linkedActivityContext(from dto: LinkedActivityDTO) -> LinkedActivityContext {
        LinkedActivityContext(id: dto.id, name: dto.name)
    }

    private static func relationship(from raw: String?) -> RelationshipContext {
        switch raw {
        case "shared_activity":
            .sharedActivity("")
        case "matched":
            .matched
        case "liked":
            .liked
        default:
            .none
        }
    }
}
