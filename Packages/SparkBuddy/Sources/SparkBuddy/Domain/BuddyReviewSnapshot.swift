// Module: SparkBuddy — Multi-dimension review aggregates (0–5).

import Foundation

public struct BuddyReviewSnapshot: Equatable, Sendable {
    public let punctuality: Double
    public let communication: Double
    public let expertise: Double
    public let safety: Double
    public let fun: Double
    public let recommend: Double
    public let reviews: [BuddyReview]

    public init(
        punctuality: Double,
        communication: Double,
        expertise: Double,
        safety: Double,
        fun: Double,
        recommend: Double,
        reviews: [BuddyReview] = []
    ) {
        self.punctuality = punctuality
        self.communication = communication
        self.expertise = expertise
        self.safety = safety
        self.fun = fun
        self.recommend = recommend
        self.reviews = reviews
    }

    public var highlightReviews: [BuddyReview] {
        Array(reviews.prefix(2))
    }

    public var dimensionRows: [(title: String, score: Double)] {
        [
            (
                String(localized: "buddy.review.punctuality", defaultValue: "守时", comment: "Punctuality"),
                punctuality
            ),
            (
                String(localized: "buddy.review.communication", defaultValue: "沟通", comment: "Communication"),
                communication
            ),
            (
                String(localized: "buddy.review.expertise", defaultValue: "专业度", comment: "Expertise"),
                expertise
            ),
            (
                String(localized: "buddy.review.safety", defaultValue: "安全感", comment: "Safety"),
                safety
            ),
            (
                String(localized: "buddy.review.fun", defaultValue: "趣味性", comment: "Fun"),
                fun
            ),
            (
                String(localized: "buddy.review.recommend", defaultValue: "推荐指数", comment: "Recommend"),
                recommend
            )
        ]
    }
}
