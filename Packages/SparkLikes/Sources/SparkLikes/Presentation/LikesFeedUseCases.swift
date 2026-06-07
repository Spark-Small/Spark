// Module: SparkLikes — Feed UseCase bundle for LikesFeedViewModel injection.

import Foundation
import SparkCore

public struct LikesFeedUseCases: Sendable {
    public let fetchFeed: any FetchLikesFeedUseCaseProtocol
    public let fetchInbound: any FetchInboundLikesUseCaseProtocol
    public let fetchViewerProfile: any FetchViewerProfileUseCaseProtocol
    public let updateViewerProfile: any UpdateViewerProfileUseCaseProtocol
    public let rewindPass: any RewindPassUseCaseProtocol
    public let submitLike: any SubmitLikeUseCaseProtocol
    public let fetchDailyStats: any FetchDailyLikeStatsUseCaseProtocol
    public let requestAvatarUpload: any RequestAvatarUploadUseCaseProtocol
    public let submitPass: any SubmitPassUseCaseProtocol
    public let submitFriendRequest: any SubmitFriendRequestUseCaseProtocol
    public let reportUser: any ReportUserUseCaseProtocol
    public let blockUser: any BlockUserUseCaseProtocol

    public init(
        fetchFeed: any FetchLikesFeedUseCaseProtocol,
        fetchInbound: any FetchInboundLikesUseCaseProtocol,
        fetchViewerProfile: any FetchViewerProfileUseCaseProtocol,
        updateViewerProfile: any UpdateViewerProfileUseCaseProtocol,
        rewindPass: any RewindPassUseCaseProtocol,
        submitLike: any SubmitLikeUseCaseProtocol,
        fetchDailyStats: any FetchDailyLikeStatsUseCaseProtocol,
        requestAvatarUpload: any RequestAvatarUploadUseCaseProtocol,
        submitPass: any SubmitPassUseCaseProtocol,
        submitFriendRequest: any SubmitFriendRequestUseCaseProtocol,
        reportUser: any ReportUserUseCaseProtocol,
        blockUser: any BlockUserUseCaseProtocol
    ) {
        self.fetchFeed = fetchFeed
        self.fetchInbound = fetchInbound
        self.fetchViewerProfile = fetchViewerProfile
        self.updateViewerProfile = updateViewerProfile
        self.rewindPass = rewindPass
        self.submitLike = submitLike
        self.fetchDailyStats = fetchDailyStats
        self.requestAvatarUpload = requestAvatarUpload
        self.submitPass = submitPass
        self.submitFriendRequest = submitFriendRequest
        self.reportUser = reportUser
        self.blockUser = blockUser
    }
}
