//
//  ActivityCommentsStore.swift
//  坐标系
//
//  活动详情评论区：委托 PlatformReviewsStore 统一持久化。
//

import Foundation
import CoordinateModels

struct ActivityComment: Identifiable, Hashable, Codable {
    let id: UUID
    var author: String
    var text: String
    var postedAt: Date
    var parentID: UUID?
    var replyToAuthor: String?
    var likeCount: Int
    var isLiked: Bool
    var dislikeCount: Int
    var isDisliked: Bool

    init(
        id: UUID = UUID(),
        author: String,
        text: String,
        postedAt: Date = .now,
        parentID: UUID? = nil,
        replyToAuthor: String? = nil,
        likeCount: Int = 0,
        isLiked: Bool = false,
        dislikeCount: Int = 0,
        isDisliked: Bool = false
    ) {
        self.id = id
        self.author = author
        self.text = text
        self.postedAt = postedAt
        self.parentID = parentID
        self.replyToAuthor = replyToAuthor
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.dislikeCount = dislikeCount
        self.isDisliked = isDisliked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        author = try container.decode(String.self, forKey: .author)
        text = try container.decode(String.self, forKey: .text)
        postedAt = try container.decode(Date.self, forKey: .postedAt)
        parentID = try container.decodeIfPresent(UUID.self, forKey: .parentID)
        replyToAuthor = try container.decodeIfPresent(String.self, forKey: .replyToAuthor)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        dislikeCount = try container.decodeIfPresent(Int.self, forKey: .dislikeCount) ?? 0
        isDisliked = try container.decodeIfPresent(Bool.self, forKey: .isDisliked) ?? false
    }
}

@MainActor
enum ActivityCommentsStore {
    private static func target(_ activityID: Activity.ID) -> PlatformReviewTarget {
        .activity(activityID)
    }

    static func comments(for activityID: Activity.ID) -> [ActivityComment] {
        PlatformReviewsStore.reviews(for: target(activityID)).map(ActivityComment.init(platformReview:))
    }

    static func resetAll() {
        PlatformReviewsStore.resetAll()
    }
}
