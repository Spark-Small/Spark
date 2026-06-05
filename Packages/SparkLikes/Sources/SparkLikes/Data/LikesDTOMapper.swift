// Module: SparkLikes — DTO → domain mapping.

import Foundation
import SparkCore

enum LikesDTOMapper {
    static func page(from dto: LikesFeedResponseDTO) -> LikesFeedPage {
        LikesFeedPage(
            items: dto.items.compactMap(card(from:)),
            nextCursor: dto.nextCursor
        )
    }

    static func inboundPage(from dto: LikesInboundResponseDTO) -> LikesInboundPage {
        LikesInboundPage(
            items: dto.items.compactMap(inboundItem(from:)),
            nextCursor: dto.nextCursor
        )
    }

    static func inboundItem(from dto: InboundLikeItemDTO) -> InboundLikeItem? {
        guard let card = card(from: dto.card) else { return nil }
        return InboundLikeItem(
            userID: UserID(dto.userID),
            card: card,
            likedAt: dto.likedAt.flatMap(parseISO8601),
            isVisible: dto.isVisible ?? true
        )
    }

    static func card(from dto: DiscoverCardDTO) -> DiscoverCard? {
        guard let primaryURL = URL(string: dto.media.url) else { return nil }
        let kind = DiscoverMediaKind(rawValue: dto.media.kind.lowercased()) ?? .image
        let poster = dto.media.posterURL.flatMap(URL.init(string:))
        let primary = DiscoverMedia(kind: kind, url: primaryURL, posterURL: poster)
        let items = (dto.mediaItems ?? []).compactMap(media(from:))
        return DiscoverCard(
            userID: UserID(dto.userID),
            displayName: dto.displayName,
            bio: dto.bio ?? "",
            gender: dto.gender.flatMap(DiscoverGender.init(wireValue:)),
            media: primary,
            mediaItems: items.isEmpty ? [primary] : items,
            interestTags: dto.interestTags ?? [],
            coarseLocation: dto.coarseLocation,
            sharedActivityTitle: dto.sharedActivity?.title,
            sharedActivityID: dto.sharedActivity?.activityID
        )
    }

    static func media(from dto: DiscoverMediaDTO) -> DiscoverMedia? {
        guard let url = URL(string: dto.url) else { return nil }
        let kind = DiscoverMediaKind(rawValue: dto.kind.lowercased()) ?? .image
        return DiscoverMedia(kind: kind, url: url, posterURL: dto.posterURL.flatMap(URL.init(string:)))
    }

    static func viewerProfile(from dto: LikesViewerProfileDTO) -> LikesViewerProfile {
        LikesViewerProfile(
            displayName: dto.displayName,
            hasPhoto: dto.hasPhoto,
            avatarURL: dto.avatarURL.flatMap(URL.init(string:))
        )
    }

    static func likeResult(from dto: LikeActionResponseDTO) -> LikeActionResult {
        let outcome = LikeActionOutcome(rawValue: dto.outcome) ?? .pending
        return LikeActionResult(outcome: outcome, threadID: dto.threadID)
    }

    private static func parseISO8601(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}
