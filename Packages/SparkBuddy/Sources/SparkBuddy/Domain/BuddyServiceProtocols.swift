// Module: SparkBuddy — Live-capable service boundaries (voice, payment, safety, match).

import Foundation

public struct BuddyVoicePreChatSession: Equatable, Sendable, Identifiable {
    public let id: String
    public let listingID: String
    public let ownerUserID: String
    public let expiresAt: Date

    public init(id: String, listingID: String, ownerUserID: String, expiresAt: Date) {
        self.id = id
        self.listingID = listingID
        self.ownerUserID = ownerUserID
        self.expiresAt = expiresAt
    }
}

public struct BuddySafetySession: Equatable, Sendable, Identifiable {
    public let id: String
    public let orderID: String
    public let isLocationSharingActive: Bool

    public init(id: String, orderID: String, isLocationSharingActive: Bool) {
        self.id = id
        self.orderID = orderID
        self.isLocationSharingActive = isLocationSharingActive
    }
}

public protocol BuddyVoicePreChatService: Sendable {
    func startSession(listingID: String, ownerUserID: String) async throws -> BuddyVoicePreChatSession
    func endSession(sessionID: String) async
}

public protocol BuddyPaymentService: Sendable {
    func initiateEscrowPayment(
        orderID: String,
        method: BuddyPaymentMethod,
        amount: Decimal,
        currencyCode: String
    ) async throws -> BuddyPaymentResult
}

public protocol BuddySafetyService: Sendable {
    func startSession(orderID: String) async throws -> BuddySafetySession
    func triggerSOS(sessionID: String) async throws
    func stopSession(sessionID: String) async
}

public protocol BuddyMatchEngineService: Sendable {
    func refreshMatchInsight(listingID: String) async throws -> BuddyMatchInsight
}
