// Module: SparkLikes — Network discover feed.

import Foundation
import os
import SparkCore
import SparkNetworking

public struct LiveLikesFeedRepository: LikesFeedRepository, Sendable {
    private let apiClient: APIClient
    private let logger = Logger(subsystem: SparkLog.subsystem, category: "LikesFeed")

    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    public func fetchFeed(query: LikesFeedQuery) async throws -> LikesFeedPage {
        try await request("fetchFeed") {
            let dto: LikesFeedResponseDTO = try await apiClient.get(LikesAPIPath.feedQuery(query: query))
            return LikesDTOMapper.page(from: dto)
        }
    }

    public func fetchInbound(cursor: String?) async throws -> LikesInboundPage {
        try await request("fetchInbound") {
            var path = LikesAPIPath.inbound
            if let cursor, !cursor.isEmpty {
                path += "?cursor=\(cursor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cursor)"
            }
            let dto: LikesInboundResponseDTO = try await apiClient.get(path)
            return LikesDTOMapper.inboundPage(from: dto)
        }
    }

    public func fetchViewerProfile() async throws -> LikesViewerProfile {
        try await request("fetchViewerProfile") {
            let dto: LikesViewerProfileDTO = try await apiClient.get(LikesAPIPath.viewerProfile)
            return LikesDTOMapper.viewerProfile(from: dto)
        }
    }

    public func updateViewerProfile(_ profile: LikesViewerProfile) async throws -> LikesViewerProfile {
        try await request("updateViewerProfile") {
            let body = try JSONEncoder().encode(
                LikesViewerProfileRequestDTO(
                    displayName: profile.displayName,
                    hasPhoto: profile.hasPhoto,
                    avatarURL: profile.avatarURL?.absoluteString
                )
            )
            let dto: LikesViewerProfileDTO = try await apiClient.patch(
                LikesAPIPath.viewerProfile,
                body: body,
                as: LikesViewerProfileDTO.self
            )
            return LikesDTOMapper.viewerProfile(from: dto)
        }
    }

    public func rewindLastPass() async throws -> DiscoverCard? {
        try await request("rewindLastPass") {
            let dto: LikesRewindResponseDTO = try await apiClient.post(LikesAPIPath.rewind, as: LikesRewindResponseDTO.self)
            guard let cardDTO = dto.card else { return nil }
            return LikesDTOMapper.card(from: cardDTO)
        }
    }

    public func fetchDailyStats() async throws -> DailyLikeStats {
        try await request("fetchDailyStats") {
            let dto: DailyLikeStatsDTO = try await apiClient.get(LikesAPIPath.dailyStats)
            return LikesDTOMapper.dailyStats(from: dto)
        }
    }

    public func submitLike(_ likeRequest: SendLikeRequest) async throws -> LikeActionResult {
        try await request("submitLike") {
            let body = try JSONEncoder().encode(LikesDTOMapper.sendLikeBody(from: likeRequest))
            let dto: LikeActionResponseDTO = try await apiClient.post(
                LikesAPIPath.like(userID: likeRequest.userID.rawValue),
                body: body,
                as: LikeActionResponseDTO.self
            )
            return LikesDTOMapper.likeResult(from: dto)
        }
    }

    public func submitPass(userID: UserID) async throws {
        try await request("submitPass") {
            try await apiClient.post(LikesAPIPath.pass(userID: userID.rawValue))
        }
    }

    public func submitFriendRequest(userID: UserID) async throws -> LikeActionResult {
        try await request("submitFriendRequest") {
            let dto: FriendRequestResponseDTO = try await apiClient.post(
                LikesAPIPath.friendRequest(userID: userID.rawValue),
                as: FriendRequestResponseDTO.self
            )
            let outcome = LikeActionOutcome(rawValue: dto.outcome) ?? .sent
            return LikeActionResult(outcome: outcome, threadID: nil)
        }
    }

    public func reportUser(userID: UserID, reason: String, detail: String?) async throws {
        try await request("reportUser") {
            let body = try JSONEncoder().encode(LikesReportRequestDTO(reason: reason, detail: detail))
            _ = try await apiClient.post(
                LikesAPIPath.report(userID: userID.rawValue),
                body: body,
                as: LikesReportResponseDTO.self
            )
        }
    }

    public func blockUser(userID: UserID) async throws {
        try await request("blockUser") {
            try await apiClient.post(LikesAPIPath.block(userID: userID.rawValue))
        }
    }

    public func syncPremiumEntitlement(isActive: Bool) async throws {
        try await request("syncPremiumEntitlement") {
            let body = try JSONEncoder().encode(LikesViewerProfileRequestDTO(isPremium: isActive))
            _ = try await apiClient.patch(
                LikesAPIPath.viewerProfile,
                body: body,
                as: LikesViewerProfileDTO.self
            )
        }
    }

    private func request<T>(_ operation: String, _ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch {
            throw logAndMap(operation, error)
        }
    }

    private func logAndMap(_ operation: String, _ error: Error) -> LikesError {
        logger.error("Likes \(operation) failed: \(String(describing: error), privacy: .public)")
        if let likesError = error as? LikesError {
            return likesError
        }
        if let appError = error as? AppError {
            return .underlying(appError)
        }
        return .underlying(.unknown(message: error.localizedDescription))
    }
}
