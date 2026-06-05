// Module: SparkLikes — Payload for recording a like action.

import Foundation
import SparkCore

public struct SendLikeRequest: Sendable, Equatable {
    public let userID: UserID
    public let intensity: LikeIntensity
    public let opener: String?
    public let likedQuestionID: String?

    public init(
        userID: UserID,
        intensity: LikeIntensity = .like,
        opener: String? = nil,
        likedQuestionID: String? = nil
    ) {
        self.userID = userID
        self.intensity = intensity
        self.opener = opener
        self.likedQuestionID = likedQuestionID
    }
}
