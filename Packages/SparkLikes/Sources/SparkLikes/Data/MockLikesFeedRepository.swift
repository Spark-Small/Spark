// Module: SparkLikes — In-memory discover feed for Mock API host.

import Foundation
import SparkCore

public actor MockLikesFeedRepository: LikesFeedRepository {
    private enum Pagination {
        static let pageTwoCursor = "mock_likes_page_2"
        static let pageSize = 2
    }

    private enum InboundPagination {
        static let pageTwoCursor = "mock_inbound_page_2"
    }

    private var passedIDs: Set<String> = []
    private var likedIDs: Set<String> = []
    private var friendRequestIDs: Set<String> = []
    private var blockedIDs: Set<String> = []
    private var connectedIDs: Set<String> = []
    private var lastPassedCard: DiscoverCard?
    private var rewindUsedOnDay: String?
    private var removedInboundIDs: Set<String> = []
    private var viewerProfile = LikesViewerProfile()

    public init() {}

    public func fetchInbound(cursor: String?) async throws -> LikesInboundPage {
        let all = MockLikesCatalog.inboundCards()
            .filter { !removedInboundIDs.contains($0.id) && !blockedIDs.contains($0.id) }
            .map { InboundLikeItem(userID: $0.userID, card: $0) }
        if cursor == InboundPagination.pageTwoCursor {
            let remainder = Array(all.dropFirst(1))
            return LikesInboundPage(items: remainder, nextCursor: nil)
        }
        let firstPage = Array(all.prefix(1))
        let hasMore = all.count > firstPage.count
        return LikesInboundPage(
            items: firstPage,
            nextCursor: hasMore ? InboundPagination.pageTwoCursor : nil
        )
    }

    public func fetchViewerProfile() async throws -> LikesViewerProfile {
        viewerProfile
    }

    public func updateViewerProfile(_ profile: LikesViewerProfile) async throws -> LikesViewerProfile {
        viewerProfile = profile
        LikesViewerProfileStore.markGateComplete(profile.isComplete)
        return profile
    }

    public func requestAvatarUploadURL(contentType: String) async throws -> URL {
        URL(string: "https://picsum.photos/seed/mock-avatar/400/400")!
    }

    public func rewindLastPass() async throws -> DiscoverCard? {
        let today = Self.dayKey(for: Date())
        if rewindUsedOnDay == today {
            throw LikesError.rewindUnavailable
        }
        guard let card = lastPassedCard else {
            throw LikesError.rewindUnavailable
        }
        passedIDs.remove(card.id)
        lastPassedCard = nil
        rewindUsedOnDay = today
        return card
    }

    public func fetchFeed(query: LikesFeedQuery) async throws -> LikesFeedPage {
        let filtered = filteredCards(query: query)
        if query.cursor == Pagination.pageTwoCursor {
            let remainder = Array(filtered.dropFirst(Pagination.pageSize))
            return LikesFeedPage(items: remainder, nextCursor: nil)
        }
        let pageOne = Array(filtered.prefix(Pagination.pageSize))
        let hasMore = filtered.count > Pagination.pageSize
        return LikesFeedPage(
            items: pageOne,
            nextCursor: hasMore ? Pagination.pageTwoCursor : nil
        )
    }

    public func submitLike(userID: UserID) async throws -> LikeActionResult {
        guard MockLikesCatalog.card(userID: userID) != nil else {
            throw LikesError.underlying(.server(statusCode: 404, message: nil))
        }
        if connectedIDs.contains(userID.rawValue) {
            return LikeActionResult(
                outcome: .alreadyConnected,
                threadID: MockLikesCatalog.directThreadID(for: userID)
            )
        }
        likedIDs.insert(userID.rawValue)
        passedIDs.insert(userID.rawValue)
        removedInboundIDs.insert(userID.rawValue)
        let isInboundLikeBack = MockLikesCatalog.inboundCards().contains { $0.userID == userID }
        if userID == MockLikesCatalog.mutualMatchUserID || isInboundLikeBack {
            connectedIDs.insert(userID.rawValue)
            return LikeActionResult(
                outcome: .matched,
                threadID: MockLikesCatalog.directThreadID(for: userID)
            )
        }
        return LikeActionResult(outcome: .pending, threadID: nil)
    }

    public func submitPass(userID: UserID) async throws {
        if let card = MockLikesCatalog.card(userID: userID) {
            lastPassedCard = card
        }
        passedIDs.insert(userID.rawValue)
    }

    public func submitFriendRequest(userID: UserID) async throws -> LikeActionResult {
        guard MockLikesCatalog.card(userID: userID) != nil else {
            throw LikesError.underlying(.server(statusCode: 404, message: nil))
        }
        if connectedIDs.contains(userID.rawValue) || friendRequestIDs.contains(userID.rawValue) {
            throw LikesError.alreadyConnected
        }
        friendRequestIDs.insert(userID.rawValue)
        passedIDs.insert(userID.rawValue)
        return LikeActionResult(outcome: .sent, threadID: nil)
    }

    public func reportUser(userID: UserID, reason: String, detail: String?) async throws {
        blockedIDs.insert(userID.rawValue)
        passedIDs.insert(userID.rawValue)
    }

    public func blockUser(userID: UserID) async throws {
        blockedIDs.insert(userID.rawValue)
        passedIDs.insert(userID.rawValue)
    }

    private func filteredCards(query: LikesFeedQuery) -> [DiscoverCard] {
        MockLikesCatalog.allCards().filter { card in
            !passedIDs.contains(card.id)
                && !blockedIDs.contains(card.id)
                && !connectedIDs.contains(card.id)
                && matchesGender(card: card, preference: query.genderPreference)
        }
    }

    private func matchesGender(card: DiscoverCard, preference: LikesGenderPreference) -> Bool {
        switch preference {
        case .all:
            return true
        case .same, .opposite:
            // REASONING: Mock viewer is treated as male for filter demo until profile API exists.
            guard let gender = card.gender else { return true }
            let viewer: DiscoverGender = .male
            if preference == .same {
                return gender == viewer
            }
            return gender != viewer && gender != .other
        }
    }

    private static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
}
