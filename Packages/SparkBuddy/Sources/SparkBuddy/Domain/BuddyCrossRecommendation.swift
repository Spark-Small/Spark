// Module: SparkBuddy — Cross-tab recommendation payload (activity ↔ buddy).

import Foundation

public struct BuddyCrossRecommendation: Equatable, Sendable {
    public let listingID: String
    public let title: String
    public let subtitle: String

    public init(listingID: String, title: String, subtitle: String) {
        self.listingID = listingID
        self.title = title
        self.subtitle = subtitle
    }
}
