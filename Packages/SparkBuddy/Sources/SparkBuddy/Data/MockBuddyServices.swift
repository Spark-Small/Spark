// Module: SparkBuddy — Mock live-capable services until backend ships.

import Foundation

public struct MockBuddyVoicePreChatService: BuddyVoicePreChatService, Sendable {
    public init() {}

    public func startSession(listingID: String, ownerUserID: String) async throws -> BuddyVoicePreChatSession {
        let session = BuddyVoicePreChatSession(
            id: "voice_mock_\(listingID)",
            listingID: listingID,
            ownerUserID: ownerUserID,
            expiresAt: Date().addingTimeInterval(15 * 60)
        )
        BuddyTelemetry.preChatStarted(sessionID: session.id, listingID: listingID)
        return session
    }

    public func endSession(sessionID: String) async {
        BuddyTelemetry.preChatEnded(sessionID: sessionID)
    }
}

public struct MockBuddyPaymentService: BuddyPaymentService, Sendable {
    public init() {}

    public func initiateEscrowPayment(
        orderID: String,
        method: BuddyPaymentMethod,
        amount: Decimal,
        currencyCode: String
    ) async throws -> BuddyPaymentResult {
        BuddyTelemetry.paymentInitiated(orderID: orderID, method: method.rawValue)
        let result = BuddyPaymentResult(
            transactionID: "pay_mock_\(orderID)",
            method: method,
            succeeded: true
        )
        BuddyTelemetry.paymentSucceeded(transactionID: result.transactionID)
        return result
    }
}

public struct MockBuddySafetyService: BuddySafetyService, Sendable {
    public init() {}

    public func startSession(orderID: String) async throws -> BuddySafetySession {
        let session = BuddySafetySession(
            id: "safety_mock_\(orderID)",
            orderID: orderID,
            isLocationSharingActive: true
        )
        BuddyTelemetry.safetySessionStarted(orderID: orderID)
        return session
    }

    public func triggerSOS(sessionID: String) async throws {
        BuddyTelemetry.sosTriggered(sessionID: sessionID)
    }

    public func stopSession(sessionID: String) async {}
}

public struct MockBuddyMatchEngineService: BuddyMatchEngineService, Sendable {
    public init() {}

    public func refreshMatchInsight(listingID: String) async throws -> BuddyMatchInsight {
        let insight = BuddyMatchInsight(
            matchPercent: Int.random(in: 82...96),
            reason: String(
                localized: "buddy.mock.match.refreshed",
                defaultValue: "基于最新兴趣标签重新计算匹配度。",
                comment: "Refreshed match reason"
            )
        )
        BuddyTelemetry.matchInsightRefreshed(listingID: listingID, matchPercent: insight.matchPercent)
        return insight
    }
}
