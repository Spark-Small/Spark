//
//  PlatformReviewsStore.swift
//  坐标系
//
//  统一评价 / 评论：本机持久化与读写。
//

import Foundation
import CoordinateModels

// MARK: - Store

@MainActor
enum PlatformReviewsStore {
    private static let fileName = "platform_reviews.json"
    private static var cache: [String: [PlatformReview]] = loadAll()

    static func reviews(for target: PlatformReviewTarget) -> [PlatformReview] {
        let key = target.storageKey
        if let list = cache[key] { return list }
        // 陪玩：无后端时不注入 Sample 假评价；仅本机写入。
        if target.kind == .companion {
            cache[key] = []
            return []
        }
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

    /// 该预约是否已写过根评价（一单一评）。
    static func hasReview(forBookingID bookingID: UUID, target: PlatformReviewTarget) -> Bool {
        reviews(for: target).contains { $0.bookingID == bookingID && $0.isRoot }
    }

    @discardableResult
    static func add(
        _ text: String,
        target: PlatformReviewTarget,
        author: String,
        parent: PlatformReview? = nil,
        rating: Int? = nil,
        serviceTitle: String? = nil,
        priceText: String? = nil,
        isAnonymous: Bool = false,
        bookingID: UUID? = nil,
        voiceLocalName: String? = nil,
        voiceDuration: Double? = nil
    ) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasVoice = {
            guard let voiceLocalName, let voiceDuration else { return false }
            return !voiceLocalName.isEmpty && voiceDuration > 0
        }()
        guard !trimmed.isEmpty || hasVoice else { return nil }
        if !trimmed.isEmpty, case .block(let reason) = ContentModeration.scanText(trimmed) {
            return reason
        }

        let resolvedParent = resolvedParentReview(parent, for: target)
        if target.kind == .companion, resolvedParent == nil {
            guard let bookingID else {
                return PlatformReviewsCopy.needCompletedOrder
            }
            if hasReview(forBookingID: bookingID, target: target) {
                return PlatformReviewsCopy.alreadyReviewed
            }
        }

        let body = trimmed.isEmpty ? PlatformReviewsCopy.voicePlaceholder : trimmed
        let key = target.storageKey
        var list = cache[key] ?? (target.kind == .companion ? [] : seedReviews(for: target))
        list.append(
            PlatformReview(
                author: author,
                text: body,
                parentID: resolvedParent?.id,
                replyToAuthor: resolvedParent.map(\.displayAuthor),
                rating: resolvedParent == nil ? rating : nil,
                serviceTitle: resolvedParent == nil ? serviceTitle : nil,
                priceText: resolvedParent == nil ? priceText : nil,
                isAnonymous: resolvedParent == nil ? isAnonymous : false,
                bookingID: resolvedParent == nil ? bookingID : nil,
                voiceLocalName: voiceLocalName,
                voiceDuration: voiceDuration
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
        let removed = list.filter {
            ($0.id == reviewID && $0.author == author) || $0.parentID == reviewID
        }
        for review in removed {
            if let name = review.voiceLocalName {
                LocalMediaLibrary.delete(named: name)
            }
        }
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

    private static let companionSeedPurgeKey = "platform_reviews.purgedAutoCompanionSeeds.v1"

    private static func loadAll() -> [String: [PlatformReview]] {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        var map: [String: [PlatformReview]] = [:]
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String: [PlatformReview]].self, from: data) {
            map = decoded
        }
        // 一次性清掉历史自动灌入的陪玩假评价（无后端前仅本机写入可信）。
        if !UserDefaults.standard.bool(forKey: companionSeedPurgeKey) {
            let before = map.count
            map = map.filter { !$0.key.hasPrefix("companion:") }
            UserDefaults.standard.set(true, forKey: companionSeedPurgeKey)
            if map.count != before, let data = try? JSONEncoder().encode(map) {
                try? data.write(to: url, options: [.atomic])
            }
        }
        return map
    }

    private static func persist() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}

