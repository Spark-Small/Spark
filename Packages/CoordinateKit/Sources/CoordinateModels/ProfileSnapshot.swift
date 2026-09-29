import Foundation

public struct ProfileSnapshot: Codable, Sendable {
    public var user: AppUser
    public var hasCompletedOnboarding: Bool
    public var blockedUserNames: [String]
    public var followedUserNames: [String]
    public var moderationTickets: [ModerationTicket]

    public init(
        user: AppUser,
        hasCompletedOnboarding: Bool,
        blockedUserNames: [String] = [],
        followedUserNames: [String] = [],
        moderationTickets: [ModerationTicket] = []
    ) {
        self.user = user
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.blockedUserNames = blockedUserNames
        self.followedUserNames = followedUserNames
        self.moderationTickets = moderationTickets
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decode(AppUser.self, forKey: .user)
        hasCompletedOnboarding = try container.decode(Bool.self, forKey: .hasCompletedOnboarding)
        blockedUserNames = try container.decodeIfPresent([String].self, forKey: .blockedUserNames) ?? []
        followedUserNames = try container.decodeIfPresent([String].self, forKey: .followedUserNames) ?? []
        moderationTickets = try container.decodeIfPresent([ModerationTicket].self, forKey: .moderationTickets) ?? []
    }
}