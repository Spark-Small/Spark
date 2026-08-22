//
//  PlatformReviewsStore.swift
//  坐标系
//
//  统一评价 / 评论：活动、陪玩等场景共用持久化、筛选与统计。
//

import Foundation

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
        region: String? = nil
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
    }

    func isOwned(by userName: String) -> Bool {
        author == userName
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
            author: author,
            text: text,
            postedAt: postedAt,
            parentID: parentID,
            replyToAuthor: replyToAuthor,
            likeCount: likeCount,
            region: region,
            isLiked: isLiked,
            dislikeCount: dislikeCount,
            isDisliked: isDisliked
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

    @MainActor
    static func displayRating(for companion: PaidCompanion) -> Double {
        let stats = PlatformReviewsStore.stats(for: .companion(companion.id))
        if let average = stats.averageRating {
            return average
        }
        let volumeBoost = min(Double(companion.orderCount), 180) / 360
        let seed = abs(companion.id.hashValue % 1000)
        return min(5.0, 4.5 + volumeBoost + Double(seed % 5) / 10)
    }

    @MainActor
    static func reviewCount(for companion: PaidCompanion) -> Int {
        let count = PlatformReviewsStore.stats(for: .companion(companion.id)).total
        return count > 0 ? count : max(2, min(companion.orderCount / 3, 999))
    }
}

// MARK: - Store

@MainActor
enum PlatformReviewsStore {
    private static let fileName = "platform_reviews.json"
    private static var cache: [String: [PlatformReview]] = loadAll()

    static func reviews(for target: PlatformReviewTarget) -> [PlatformReview] {
        let key = target.storageKey
        if let list = cache[key] { return list }
        let seeds = seedReviews(for: target)
        if !seeds.isEmpty {
            cache[key] = seeds
            persist()
        }
        return seeds
    }

    static func stats(for target: PlatformReviewTarget) -> PlatformReviewStats {
        PlatformReviewCatalog.stats(for: reviews(for: target))
    }

    @discardableResult
    static func add(
        _ text: String,
        target: PlatformReviewTarget,
        author: String,
        parent: PlatformReview? = nil,
        rating: Int? = nil,
        serviceTitle: String? = nil,
        priceText: String? = nil
    ) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let word = ContentModeration.containsSensitive(trimmed) {
            return "评论包含敏感词「\(word)」"
        }

        let key = target.storageKey
        var list = cache[key] ?? seedReviews(for: target)
        let resolvedParent = resolvedParentReview(parent, for: target)
        list.append(
            PlatformReview(
                author: author,
                text: trimmed,
                parentID: resolvedParent?.id,
                replyToAuthor: resolvedParent?.author,
                rating: resolvedParent == nil ? rating : nil,
                serviceTitle: resolvedParent == nil ? serviceTitle : nil,
                priceText: resolvedParent == nil ? priceText : nil
            )
        )
        cache[key] = list
        persist()
        return nil
    }

    static func toggleLike(reviewID: UUID, target: PlatformReviewTarget) {
        let key = target.storageKey
        _ = reviews(for: target)
        guard var list = cache[key],
              let index = list.firstIndex(where: { $0.id == reviewID })
        else { return }

        if list[index].isLiked {
            list[index].isLiked = false
            list[index].likeCount = max(list[index].likeCount - 1, 0)
        } else {
            if list[index].isDisliked {
                list[index].isDisliked = false
                list[index].dislikeCount = max(list[index].dislikeCount - 1, 0)
            }
            list[index].isLiked = true
            list[index].likeCount += 1
        }
        cache[key] = list
        persist()
    }

    static func toggleDislike(reviewID: UUID, target: PlatformReviewTarget) {
        let key = target.storageKey
        _ = reviews(for: target)
        guard var list = cache[key],
              let index = list.firstIndex(where: { $0.id == reviewID })
        else { return }

        if list[index].isDisliked {
            list[index].isDisliked = false
            list[index].dislikeCount = max(list[index].dislikeCount - 1, 0)
        } else {
            if list[index].isLiked {
                list[index].isLiked = false
                list[index].likeCount = max(list[index].likeCount - 1, 0)
            }
            list[index].isDisliked = true
            list[index].dislikeCount += 1
        }
        cache[key] = list
        persist()
    }

    static func delete(reviewID: UUID, target: PlatformReviewTarget, author: String) {
        let key = target.storageKey
        guard var list = cache[key] else { return }
        list.removeAll {
            ($0.id == reviewID && $0.author == author)
                || $0.parentID == reviewID
        }
        cache[key] = list
        persist()
    }

    static func importReviews(_ reviews: [PlatformReview], for target: PlatformReviewTarget) {
        let key = target.storageKey
        guard cache[key]?.isEmpty != false else { return }
        guard !reviews.isEmpty else { return }
        cache[key] = reviews
        persist()
    }

    static func removeAll(for target: PlatformReviewTarget) {
        cache[target.storageKey] = nil
        persist()
    }

    static func resetAll() {
        cache = [:]
        persist()
    }

    // MARK: Seeds

    private static func resolvedParentReview(
        _ parent: PlatformReview?,
        for target: PlatformReviewTarget
    ) -> PlatformReview? {
        guard let parent else { return nil }
        guard target.kind == .community else { return parent }
        return PlatformReview(
            id: parent.parentID ?? parent.id,
            author: parent.author,
            text: parent.text,
            postedAt: parent.postedAt,
            parentID: parent.parentID,
            replyToAuthor: parent.replyToAuthor,
            likeCount: parent.likeCount,
            isLiked: parent.isLiked,
            dislikeCount: parent.dislikeCount,
            isDisliked: parent.isDisliked,
            region: parent.region
        )
    }

    private static func seedReviews(for target: PlatformReviewTarget) -> [PlatformReview] {
        switch target.kind {
        case .activity:
            guard let activityID = UUID(uuidString: target.id) else { return [] }
            return seedActivityComments(activityID: activityID)
        case .companion:
            guard let companionID = UUID(uuidString: target.id),
                  let companion = SampleData.paidCompanions.first(where: { $0.id == companionID })
            else { return [] }
            return seedCompanionReviews(companion: companion)
        case .community:
            guard let postID = UUID(uuidString: target.id) else { return [] }
            return seedCommunityComments(postID: postID)
        }
    }

    private static func seedCommunityComments(postID: CommunityPost.ID) -> [PlatformReview] {
        guard let post = SampleData.posts.first(where: { $0.id == postID }) else { return [] }
        return post.comments.map { PlatformReview(communityComment: $0) }
    }

    private static func seedActivityComments(activityID: Activity.ID) -> [PlatformReview] {
        guard let activity = SampleData.activities.first(where: { $0.id == activityID }) else {
            return []
        }
        let seeds: [(String, String, Int, Int)] = [
            ("Mia", "想确认一下集合地点具体在哪边？", -180, 12),
            ("阿凯", "还有名额吗？我可以带一位朋友吗？", -120, 5),
            ("小周", "上次参加过\(activity.hostName)的局，组织很靠谱。", -60, 21)
        ]
        let count = 1 + abs(activity.id.stableSeed % 3)
        var comments = seeds.prefix(count).map { author, text, minutes, likes in
            PlatformReview(
                author: author,
                text: text,
                postedAt: Date().addingTimeInterval(TimeInterval(minutes * 60)),
                likeCount: likes
            )
        }
        if let first = comments.first {
            comments.append(
                PlatformReview(
                    author: activity.hostName,
                    text: "门口白色标识那边集合，我提前 10 分钟到～",
                    postedAt: first.postedAt.addingTimeInterval(8 * 60),
                    parentID: first.id,
                    replyToAuthor: first.author,
                    likeCount: 3
                )
            )
        }
        return comments
    }

    private static func seedCompanionReviews(companion: PaidCompanion) -> [PlatformReview] {
        let skus = BuddyCompanionServiceMenu.skus(for: companion)
        let templates: [(String, String)] = [
            ("星星睡着了", "声音很好听，聊天不尬，会接梗也会照顾情绪，下次还约。"),
            ("阿岚", "节奏很稳，全程照顾新手，结束还给了练习建议。"),
            ("小北", "准时到场，沟通顺畅，体验很舒服，性价比不错。"),
            ("绵绵", "专业又耐心，推荐给想认真玩的朋友，不是敷衍型。"),
            ("河马", "氛围轻松，不会冷场，线下见面也帮找了合适的店。"),
            ("晚风", "讲解清楚，结束后还给了复习建议，很负责。"),
            ("柚子茶", "会提前确认需求，过程中很主动，整体超预期。"),
            ("木木", "第一次约陪玩，体验很好，没有推销也没有冷场。"),
            ("阿哲", "技术在线，态度也好，约的套餐时长刚刚好。"),
            ("南枝", "有图有真相，现场比照片还自然，聊天也很舒服。")
        ]
        let syntheticTotal = max(2, min(companion.orderCount / 3, 999))
        let visible = min(10, max(4, syntheticTotal / 8))
        let seed = abs(companion.id.hashValue)

        return (0..<visible).map { index in
            let template = templates[(seed + index) % templates.count]
            let sku = skus[(seed + index) % max(skus.count, 1)]
            let rating = index == visible - 1 && visible > 4 ? 4 : 5
            let includesPhotos = index % 3 == 0 || index == 1
            let photoCount = includesPhotos ? (index == 1 ? 3 : 2) : 0
            let photos = (0..<photoCount).map { photoIndex in
                PlatformReviewPhotoRef(
                    seed: seed &+ index &* 17 &+ photoIndex &* 31,
                    symbol: photoIndex == 0 ? "photo" : "camera.fill"
                )
            }

            return PlatformReview(
                author: template.0,
                text: template.1,
                postedAt: companionReviewPostedAt(index: index, seed: seed),
                likeCount: 6 + (index * 7) + (seed % 5),
                rating: rating,
                serviceTitle: sku.title,
                priceText: sku.priceText,
                photoRefs: photos
            )
        }
    }

    private static func companionReviewPostedAt(index: Int, seed: Int) -> Date {
        let calendar = Calendar.current
        let now = Date.now
        switch index {
        case 0:
            return calendar.date(byAdding: .hour, value: -(2 + seed % 4), to: now) ?? now
        case 1:
            var parts = calendar.dateComponents([.year, .month, .day], from: now)
            parts.day = (parts.day ?? 1) - 1
            parts.hour = 23
            parts.minute = 30
            return calendar.date(from: parts) ?? now
        case 2:
            return calendar.date(byAdding: .day, value: -2, to: now) ?? now
        default:
            let days = 3 + index * 2 + (seed % 3)
            return calendar.date(byAdding: .day, value: -days, to: now) ?? now
        }
    }

    private static func loadAll() -> [String: [PlatformReview]] {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [PlatformReview]].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func persist() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: url, options: [.atomic])
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
            region: communityComment.region
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
