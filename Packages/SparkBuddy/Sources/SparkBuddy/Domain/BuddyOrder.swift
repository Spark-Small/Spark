// Module: SparkBuddy — Escrow booking draft and confirmation.

import Foundation

public struct BuddyOrderDraft: Sendable, Equatable {
    public let listingID: String
    public let packageID: String
    public let scheduledAt: Date
    public let paymentMethod: BuddyPaymentMethod

    public init(
        listingID: String,
        packageID: String,
        scheduledAt: Date,
        paymentMethod: BuddyPaymentMethod = .wechatPay
    ) {
        self.listingID = listingID
        self.packageID = packageID
        self.scheduledAt = scheduledAt
        self.paymentMethod = paymentMethod
    }
}

public struct BuddyOrderConfirmation: Identifiable, Equatable, Sendable {
    public let id: String
    public let listingID: String
    public let packageID: String
    public let escrowHeld: Bool

    public init(id: String, listingID: String, packageID: String, escrowHeld: Bool) {
        self.id = id
        self.listingID = listingID
        self.packageID = packageID
        self.escrowHeld = escrowHeld
    }
}
