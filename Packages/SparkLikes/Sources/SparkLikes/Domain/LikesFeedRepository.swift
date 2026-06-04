// Module: SparkLikes — Discover feed and social actions.

import Foundation
import SparkCore

public struct LikesFeedQuery: Sendable, Equatable {
    public var cursor: String?
    public var genderPreference: LikesGenderPreference
    public var intent: LikesIntent

    public init(
        cursor: String? = nil,
        genderPreference: LikesGenderPreference = .all,
        intent: LikesIntent = .match
    ) {
        self.cursor = cursor
        self.genderPreference = genderPreference
        self.intent = intent
    }
}

/// Discover feed and like/pass/friend/report/block (Mock + Live).
public protocol LikesFeedRepository: Sendable {
    func fetchFeed(query: LikesFeedQuery) async throws -> LikesFeedPage
    func fetchInbound(cursor: String?) async throws -> LikesInboundPage
    func fetchViewerProfile() async throws -> LikesViewerProfile
    func updateViewerProfile(_ profile: LikesViewerProfile) async throws -> LikesViewerProfile
    func rewindLastPass() async throws -> DiscoverCard?
    func submitLike(userID: UserID) async throws -> LikeActionResult
    func submitPass(userID: UserID) async throws
    func submitFriendRequest(userID: UserID) async throws -> LikeActionResult
    func reportUser(userID: UserID, reason: String, detail: String?) async throws
    func blockUser(userID: UserID) async throws
}
