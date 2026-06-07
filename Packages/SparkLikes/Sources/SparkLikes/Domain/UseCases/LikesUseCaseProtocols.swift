// Module: SparkLikes — UseCase protocols for ViewModel testability.

import Foundation
import SparkCore

public protocol FetchLikesFeedUseCaseProtocol: Sendable {
    func callAsFunction(query: LikesFeedQuery) async throws -> LikesFeedPage
}

public protocol FetchInboundLikesUseCaseProtocol: Sendable {
    func callAsFunction(cursor: String?) async throws -> LikesInboundPage
}

public protocol FetchViewerProfileUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> LikesViewerProfile
}

public protocol UpdateViewerProfileUseCaseProtocol: Sendable {
    func callAsFunction(_ profile: LikesViewerProfile) async throws -> LikesViewerProfile
}

public protocol RewindPassUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> DiscoverCard?
}

public protocol SubmitLikeUseCaseProtocol: Sendable {
    func callAsFunction(_ request: SendLikeRequest) async throws -> LikeActionResult
}

public protocol FetchDailyLikeStatsUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> DailyLikeStats
}

public protocol RequestAvatarUploadUseCaseProtocol: Sendable {
    func callAsFunction(contentType: String) async throws -> AvatarUploadPrepared
}

public protocol SubmitPassUseCaseProtocol: Sendable {
    func callAsFunction(userID: UserID) async throws
}

public protocol SubmitFriendRequestUseCaseProtocol: Sendable {
    func callAsFunction(userID: UserID) async throws -> LikeActionResult
}

public protocol ReportUserUseCaseProtocol: Sendable {
    func callAsFunction(userID: UserID, reason: String, detail: String?) async throws
}

public protocol BlockUserUseCaseProtocol: Sendable {
    func callAsFunction(userID: UserID) async throws
}

public protocol SyncPremiumEntitlementUseCaseProtocol: Sendable {
    func callAsFunction(isActive: Bool) async throws
}

extension FetchLikesFeedUseCase: FetchLikesFeedUseCaseProtocol {}
extension FetchInboundLikesUseCase: FetchInboundLikesUseCaseProtocol {}
extension FetchViewerProfileUseCase: FetchViewerProfileUseCaseProtocol {}
extension UpdateViewerProfileUseCase: UpdateViewerProfileUseCaseProtocol {}
extension RewindPassUseCase: RewindPassUseCaseProtocol {}
extension SubmitLikeUseCase: SubmitLikeUseCaseProtocol {}
extension FetchDailyLikeStatsUseCase: FetchDailyLikeStatsUseCaseProtocol {}
extension RequestAvatarUploadUseCase: RequestAvatarUploadUseCaseProtocol {}
extension SubmitPassUseCase: SubmitPassUseCaseProtocol {}
extension SubmitFriendRequestUseCase: SubmitFriendRequestUseCaseProtocol {}
extension ReportUserUseCase: ReportUserUseCaseProtocol {}
extension BlockUserUseCase: BlockUserUseCaseProtocol {}
extension SyncPremiumEntitlementUseCase: SyncPremiumEntitlementUseCaseProtocol {}
