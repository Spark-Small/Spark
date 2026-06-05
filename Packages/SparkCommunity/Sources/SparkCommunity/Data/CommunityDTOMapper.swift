// Module: SparkCommunity — DTO mapping.

import Foundation

enum CommunityDTOMapper {
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
            replyCount: dto.replyCount,
            replies: (dto.replies ?? []).map(reply)
        )
    }

    static func reply(from dto: CommunityPostReplyDTO) -> CommunityPostReply {
        CommunityPostReply(
            id: dto.id,
            body: dto.body,
            authorDisplayName: dto.authorDisplayName,
            createdAt: dto.createdAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        )
    }
}
