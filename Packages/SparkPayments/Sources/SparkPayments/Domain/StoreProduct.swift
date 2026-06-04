// Module: SparkPayments — Store product snapshot for UI and purchase.

import Foundation

public struct StoreProduct: Identifiable, Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let displayPrice: String

    public init(id: String, displayName: String, displayPrice: String) {
        self.id = id
        self.displayName = displayName
        self.displayPrice = displayPrice
    }
}
