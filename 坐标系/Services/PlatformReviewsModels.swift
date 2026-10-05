//
//  PlatformReviewsModels.swift
//  坐标系
//
//  评价目标 / 模型 / 统计与筛选（与 Store 分文件，≤400）。
//

import Foundation
import CoordinateModels

// MARK: - Target

struct PlatformReviewTarget: Hashable, Codable {
    enum Kind: String, Codable {
        case activity
        case companion
        case community
    }

    var kind: Kind
    var id: String

    static func activity(_ activityID: Activity.ID) -> PlatformReviewTarget {
        PlatformReviewTarget(kind: .activity, id: activityID.uuidString)
    }

    static func companion(_ companionID: PaidCompanion.ID) -> PlatformReviewTarget {
        PlatformReviewTarget(kind: .companion, id: companionID.uuidString)
    }

    static func community(_ postID: CommunityPost.ID) -> PlatformReviewTarget {
        PlatformReviewTarget(kind: .community, id: postID.uuidString)
    }

    var storageKey: String { "\(kind.rawValue):\(id)" }
}

// MARK: - Model

struct PlatformReviewPhotoRef: Codable, Hashable {
    var seed: Int
    var symbol: String

    init(seed: Int, symbol: String) {
        self.seed = seed
        self.symbol = symbol
    }

    init(_ ref: CommunityPhotoRef) {
        if case .seeded(let seed, let symbol) = ref {
            self.seed = seed
            self.symbol = symbol
        } else {
            self.seed = 0
            self.symbol = "photo"
        }
    }

    var communityPhotoRef: CommunityPhotoRef {
        .seeded(seed: seed, symbol: symbol)
    }
}

struct PlatformReview: Identifiable, Hashable, Codable {
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
    /// 陪玩履约评价：1–5 星；活动评论为 nil
    var rating: Int?
    var serviceTitle: String?
    var priceText: String?
    var photoRefs: [PlatformReviewPhotoRef]
    /// 社区评论演示用地名
    var region: String?
    /// 展示匿名；`author` 仍保留真实账号名供本机所有权 / 防刷。
    var isAnonymous: Bool
    /// 陪玩履约评价绑定的订单；一单一评。
    var bookingID: UUID?
    /// 本机语音（LocalMediaLibrary 文件名）；未上云。
    var voiceLocalName: String?
    var voiceDuration: Double?

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
        isDisliked: Bool = false,
        rating: Int? = nil,
        serviceTitle: String? = nil,
        priceText: String? = nil,
        photoRefs: [PlatformReviewPhotoRef] = [],
        region: String? = nil,
        isAnonymous: Bool = false,
        bookingID: UUID? = nil,
        voiceLocalName: String? = nil,
        voiceDuration: Double? = nil
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
        self.rating = rating
        self.serviceTitle = serviceTitle
        self.priceText = priceText
        self.photoRefs = photoRefs
        self.region = region
        self.isAnonymous = isAnonymous
        self.bookingID = bookingID
        self.voiceLocalName = voiceLocalName
        self.voiceDuration = voiceDuration
    }

    func isOwned(by userName: String) -> Bool {
        author == userName
    }

    /// 列表展示名（匿名时不露真实昵称；文案与 `PlatformReviewsCopy.anonymousAuthor` 对齐）。
    var displayAuthor: String {
        isAnonymous ? "匿名用户" : author
    }

    var isRoot: Bool { parentID == nil }

    var isPositive: Bool { (rating ?? 5) >= 4 }

    var hasPhotos: Bool { !photoRefs.isEmpty }

    var hasRating: Bool { rating != nil }

    var serviceLine: String? {
        guard let serviceTitle, let priceText else { return nil }
        return "\(serviceTitle) | \(priceText)"
    }

    var asCommunityComment: CommunityComment {
        CommunityComment(
            id: id,
            author: displayAuthor,
            text: text,
            postedAt: postedAt,
            parentID: parentID,
            replyToAuthor: replyToAuthor,
            likeCount: likeCount,
            region: region,
            isLiked: isLiked,
            dislikeCount: dislikeCount,
            isDisliked: isDisliked,
            voiceLocalName: voiceLocalName,
            voiceDuration: voiceDuration
        )
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
        rating = try container.decodeIfPresent(Int.self, forKey: .rating)
        serviceTitle = try container.decodeIfPresent(String.self, forKey: .serviceTitle)
        priceText = try container.decodeIfPresent(String.self, forKey: .priceText)
        photoRefs = try container.decodeIfPresent([PlatformReviewPhotoRef].self, forKey: .photoRefs) ?? []
        region = try container.decodeIfPresent(String.self, forKey: .region)
        isAnonymous = try container.decodeIfPresent(Bool.self, forKey: .isAnonymous) ?? false
        bookingID = try container.decodeIfPresent(UUID.self, forKey: .bookingID)
        voiceLocalName = try container.decodeIfPresent(String.self, forKey: .voiceLocalName)
        voiceDuration = try container.decodeIfPresent(Double.self, forKey: .voiceDuration)
    }

    var hasVoice: Bool {
        guard let voiceLocalName, let voiceDuration else { return false }
        return !voiceLocalName.isEmpty && voiceDuration > 0
    }
}

// MARK: - Stats / Filter

struct PlatformReviewStats: Hashable {
    var total: Int
    var positive: Int
    var withPhotos: Int
    var averageRating: Double?

    static let empty = PlatformReviewStats(total: 0, positive: 0, withPhotos: 0, averageRating: nil)
}

enum PlatformReviewFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case positive = "好评"
    case withPhotos = "有图"
    case latest = "最新"

    var id: String { rawValue }
}

enum PlatformReviewCatalog {
    static func stats(for reviews: [PlatformReview]) -> PlatformReviewStats {
        let roots = reviews.filter(\.isRoot)
        guard !roots.isEmpty else { return .empty }

        let rated = roots.compactMap(\.rating)
        let positive = roots.filter(\.isPositive).count
        let withPhotos = roots.filter(\.hasPhotos).count
        let average = rated.isEmpty
            ? nil
            : Double(rated.reduce(0, +)) / Double(rated.count)

        return PlatformReviewStats(
            total: roots.count,
            positive: positive,
            withPhotos: withPhotos,
            averageRating: average
        )
    }

    static func sortedRoots(_ reviews: [PlatformReview]) -> [PlatformReview] {
        reviews
            .filter(\.isRoot)
            .sorted { $0.postedAt > $1.postedAt }
    }

    static func filtered(_ reviews: [PlatformReview], filter: PlatformReviewFilter) -> [PlatformReview] {
        let roots: [PlatformReview]
        switch filter {
        case .all, .latest:
            roots = reviews.filter(\.isRoot)
        case .positive:
            roots = reviews.filter { $0.isRoot && $0.isPositive }
        case .withPhotos:
            roots = reviews.filter { $0.isRoot && $0.hasPhotos }
        }
        return sortedRoots(roots)
    }

    /// 仅真实评价均分；无评价返回 `nil`（禁止哈希/成单量假分）。
    @MainActor
    static func displayRating(for companion: PaidCompanion) -> Double? {
        PlatformReviewsStore.stats(for: .companion(companion.id)).averageRating
    }

    /// 仅真实评价条数。
    @MainActor
    static func reviewCount(for companion: PaidCompanion) -> Int {
        PlatformReviewsStore.stats(for: .companion(companion.id)).total
    }
}

// MARK: - Community bridge

extension PlatformReview {
    init(communityComment: CommunityComment, isLiked: Bool? = nil) {
        self.init(
            id: communityComment.id,
            author: communityComment.author,
            text: communityComment.text,
            postedAt: communityComment.postedAt,
            parentID: communityComment.parentID,
            replyToAuthor: communityComment.replyToAuthor,
            likeCount: communityComment.likeCount,
            isLiked: isLiked ?? communityComment.isLiked,
            dislikeCount: communityComment.dislikeCount,
            isDisliked: communityComment.isDisliked,
            region: communityComment.region,
            voiceLocalName: communityComment.voiceLocalName,
            voiceDuration: communityComment.voiceDuration
        )
    }
}

// MARK: - Activity bridge

extension ActivityComment {
    init(platformReview: PlatformReview) {
        self.init(
            id: platformReview.id,
            author: platformReview.author,
            text: platformReview.text,
            postedAt: platformReview.postedAt,
            parentID: platformReview.parentID,
            replyToAuthor: platformReview.replyToAuthor,
            likeCount: platformReview.likeCount,
            isLiked: platformReview.isLiked,
            dislikeCount: platformReview.dislikeCount,
            isDisliked: platformReview.isDisliked
        )
    }
}
