// Module: SparkBuddy — Standardized escrow packages (no hidden fees).

import Foundation

/// Fixed-price service bundle shown before booking.
public struct BuddyServicePackage: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let durationHours: Int
    public let priceAmount: Decimal
    public let priceCurrencyCode: String
    public let inclusions: [String]
    public let exclusions: [String]

    public init(
        id: String,
        title: String,
        durationHours: Int,
        priceAmount: Decimal,
        priceCurrencyCode: String,
        inclusions: [String],
        exclusions: [String]
    ) {
        self.id = id
        self.title = title
        self.durationHours = durationHours
        self.priceAmount = priceAmount
        self.priceCurrencyCode = priceCurrencyCode
        self.inclusions = inclusions
        self.exclusions = exclusions
    }
}
