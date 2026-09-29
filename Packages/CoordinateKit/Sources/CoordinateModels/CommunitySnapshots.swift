import Foundation

public struct CommunityComment: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var author: String
    public var text: String
    public var postedAt: Date
    /// 顶层评论为 nil；回复指向父评论
    public var parentID: UUID?
    /// 回复对象昵称（展示「A ▶ B」）
    public var replyToAuthor: String?
    public var likeCount: Int
    /// 演示用地名，可空
    public var region: String?
    /// 当前用户是否已赞（运行时；社区评论从 PlatformReviewsStore 读出时填充）
    public var isLiked: Bool
    public var dislikeCount: Int
    /// 当前用户是否已踩（运行时）
    public var isDisliked: Bool

    public init(
        id: UUID,
        author: String,
        text: String,
        postedAt: Date,
        parentID: UUID? = nil,
        replyToAuthor: String? = nil,
        likeCount: Int = 0,
        region: String? = nil,
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
        self.region = region
        self.isLiked = isLiked
        self.dislikeCount = dislikeCount
        self.isDisliked = isDisliked
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        author = try container.decode(String.self, forKey: .author)
        text = try container.decode(String.self, forKey: .text)
        postedAt = try container.decode(Date.self, forKey: .postedAt)
        parentID = try container.decodeIfPresent(UUID.self, forKey: .parentID)
        replyToAuthor = try container.decodeIfPresent(String.self, forKey: .replyToAuthor)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        region = try container.decodeIfPresent(String.self, forKey: .region)
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        dislikeCount = try container.decodeIfPresent(Int.self, forKey: .dislikeCount) ?? 0
        isDisliked = try container.decodeIfPresent(Bool.self, forKey: .isDisliked) ?? false
    }

    public var isReply: Bool { parentID != nil }

    func isOwned(by currentUserName: String) -> Bool {
        author == currentUserName
    }
}

public struct CommunityPost: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public var author: String
    public var title: String
    public var body: String
    public var tags: [String]
    public var likeCount: Int
    public var commentCount: Int
    public var repostCount: Int
    public var shareCount: Int
    public var postedAt: Date
    public var isPinned: Bool
    /// 配图种子（本地 SeededSceneFill）
    public var photoSeeds: [Int]
    public var photoHue: Double
    /// 用户发布的本地图片文件名（Documents/CommunityPhotos）
    public var localPhotoNames: [String]
    /// 关联活动名（详情内弱转化；优先用 relatedActivityID）
    public var relatedActivityTitle: String?
    public var relatedActivityID: UUID?
    public var comments: [CommunityComment]
    /// 点赞者昵称（含当前用户）
    public var likerNames: [String]
    /// 被举报次数（本地治理）
    public var reportCount: Int
    /// 转发自原帖
    public var repostedFromID: UUID?
    public var quoteText: String?

    public init(
        id: UUID,
        author: String,
        title: String,
        body: String,
        tags: [String],
        likeCount: Int,
        commentCount: Int,
        repostCount: Int,
        shareCount: Int,
        postedAt: Date,
        isPinned: Bool,
        photoSeeds: [Int],
        photoHue: Double,
        localPhotoNames: [String] = [],
        relatedActivityTitle: String? = nil,
        relatedActivityID: UUID? = nil,
        comments: [CommunityComment] = [],
        likerNames: [String] = [],
        reportCount: Int = 0,
        repostedFromID: UUID? = nil,
        quoteText: String? = nil
    ) {
        self.id = id
        self.author = author
        self.title = title
        self.body = body
        self.tags = tags
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.repostCount = repostCount
        self.shareCount = shareCount
        self.postedAt = postedAt
        self.isPinned = isPinned
        self.photoSeeds = photoSeeds
        self.photoHue = photoHue
        self.localPhotoNames = localPhotoNames
        self.relatedActivityTitle = relatedActivityTitle
        self.relatedActivityID = relatedActivityID
        self.comments = comments
        self.likerNames = likerNames
        self.reportCount = reportCount
        self.repostedFromID = repostedFromID
        self.quoteText = quoteText
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        author = try container.decode(String.self, forKey: .author)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        tags = try container.decode([String].self, forKey: .tags)
        likeCount = try container.decode(Int.self, forKey: .likeCount)
        commentCount = try container.decode(Int.self, forKey: .commentCount)
        repostCount = try container.decode(Int.self, forKey: .repostCount)
        shareCount = try container.decode(Int.self, forKey: .shareCount)
        postedAt = try container.decode(Date.self, forKey: .postedAt)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        photoSeeds = try container.decode([Int].self, forKey: .photoSeeds)
        photoHue = try container.decode(Double.self, forKey: .photoHue)
        localPhotoNames = try container.decodeIfPresent([String].self, forKey: .localPhotoNames) ?? []
        relatedActivityTitle = try container.decodeIfPresent(String.self, forKey: .relatedActivityTitle)
        relatedActivityID = try container.decodeIfPresent(UUID.self, forKey: .relatedActivityID)
        comments = try container.decodeIfPresent([CommunityComment].self, forKey: .comments) ?? []
        likerNames = try container.decodeIfPresent([String].self, forKey: .likerNames) ?? []
        reportCount = try container.decodeIfPresent(Int.self, forKey: .reportCount) ?? 0
        repostedFromID = try container.decodeIfPresent(UUID.self, forKey: .repostedFromID)
        quoteText = try container.decodeIfPresent(String.self, forKey: .quoteText)
    }

    public var isRepost: Bool { repostedFromID != nil }

    /// 用户可见正文（引用转发优先展示 quote）。
    public var messageText: String {
        if let quote = quoteText?.trimmingCharacters(in: .whitespacesAndNewlines), !quote.isEmpty {
            return quote
        }
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var shareText: String {
        "【坐标系·社区】\(messageText)"
    }

    public func isOwned(by currentUserName: String) -> Bool {
        author == currentUserName
    }
}

public struct CommunitySnapshot: Codable, Sendable {
    public var posts: [CommunityPost]
    public var likedIDs: [UUID]
    public var repostedIDs: [UUID]
    public var bookmarkedIDs: [UUID]
    public var bookmarkCollections: [String: String]
    public var reportedIDs: [UUID]
    public var likedCommentIDs: [UUID]
    public init(
        posts: [CommunityPost],
        likedIDs: [UUID],
        repostedIDs: [UUID],
        bookmarkedIDs: [UUID],
        bookmarkCollections: [String: String],
        reportedIDs: [UUID],
        likedCommentIDs: [UUID] = []
    ) {
        self.posts = posts
        self.likedIDs = likedIDs
        self.repostedIDs = repostedIDs
        self.bookmarkedIDs = bookmarkedIDs
        self.bookmarkCollections = bookmarkCollections
        self.reportedIDs = reportedIDs
        self.likedCommentIDs = likedCommentIDs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        posts = try container.decode([CommunityPost].self, forKey: .posts)
        likedIDs = try container.decode([UUID].self, forKey: .likedIDs)
        repostedIDs = try container.decode([UUID].self, forKey: .repostedIDs)
        bookmarkedIDs = try container.decode([UUID].self, forKey: .bookmarkedIDs)
        bookmarkCollections = try container.decode([String: String].self, forKey: .bookmarkCollections)
        reportedIDs = try container.decode([UUID].self, forKey: .reportedIDs)
        likedCommentIDs = try container.decodeIfPresent([UUID].self, forKey: .likedCommentIDs) ?? []
    }
}
