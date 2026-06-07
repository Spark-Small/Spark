// Module: SparkCommunity — Profile preview for community-context sheets.

import Foundation

struct CommunityProfilePreview: Identifiable, Equatable {
    let id: String
    let displayName: String
    let avatarURL: URL?
    let bio: String
    let relationship: RelationshipContext

    init(person: DiscoveredPerson) {
        id = person.id
        displayName = person.displayName
        avatarURL = person.avatarURL
        bio = person.sharedTag
        relationship = person.relationship
    }

    init(member: CommunityMember) {
        id = member.id
        displayName = member.displayName
        avatarURL = member.avatarURL
        bio = member.bio
        relationship = member.relationship
    }

    init(feedPost: CommunityFeedPost) {
        id = feedPost.authorUserID
        displayName = feedPost.authorDisplayName
        avatarURL = feedPost.authorAvatarURL
        bio = feedPost.communityName
        relationship = feedPost.relationshipToViewer
    }
}
