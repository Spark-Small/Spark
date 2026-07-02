// Module: SparkBuddy — Provider + live service use cases.

import Foundation

public struct FetchBuddyProviderStatusUseCase: FetchBuddyProviderStatusUseCaseProtocol, Sendable {
    private let repository: any BuddyRepository
    public init(repository: any BuddyRepository) { self.repository = repository }
    public func callAsFunction() async throws -> BuddyProviderStatus {
        try await repository.fetchProviderStatus()
    }
}

public struct SubmitBuddyProviderApplicationUseCase: SubmitBuddyProviderApplicationUseCaseProtocol, Sendable {
    private let repository: any BuddyRepository
    public init(repository: any BuddyRepository) { self.repository = repository }
    public func callAsFunction(draft: BuddyProviderApplicationDraft) async throws -> BuddyProviderStatus {
        guard draft.isValid else { throw BuddyError.invalidApplication }
        return try await repository.submitProviderApplication(draft)
    }
}

public struct FetchBuddyProviderEarningsUseCase: FetchBuddyProviderEarningsUseCaseProtocol, Sendable {
    private let repository: any BuddyRepository
    public init(repository: any BuddyRepository) { self.repository = repository }
    public func callAsFunction() async throws -> BuddyProviderEarnings {
        let status = try await repository.fetchProviderStatus()
        guard status.canAccessEarnings else { throw BuddyError.providerNotApproved }
        return try await repository.fetchProviderEarnings()
    }
}

public struct FetchBuddyProviderOrdersUseCase: FetchBuddyProviderOrdersUseCaseProtocol, Sendable {
    private let repository: any BuddyRepository
    public init(repository: any BuddyRepository) { self.repository = repository }
    public func callAsFunction() async throws -> [BuddyProviderOrder] {
        let status = try await repository.fetchProviderStatus()
        guard status.canAccessEarnings else { throw BuddyError.providerNotApproved }
        return try await repository.fetchProviderOrders()
    }
}

public struct RefreshBuddyMatchInsightUseCase: RefreshBuddyMatchInsightUseCaseProtocol, Sendable {
    private let matchEngine: any BuddyMatchEngineService
    public init(matchEngine: any BuddyMatchEngineService) { self.matchEngine = matchEngine }
    public func callAsFunction(listingID: String) async throws -> BuddyMatchInsight {
        try await matchEngine.refreshMatchInsight(listingID: listingID)
    }
}

public struct InitiateBuddyEscrowPaymentUseCase: InitiateBuddyEscrowPaymentUseCaseProtocol, Sendable {
    private let paymentService: any BuddyPaymentService
    public init(paymentService: any BuddyPaymentService) { self.paymentService = paymentService }
    public func callAsFunction(
        orderID: String,
        method: BuddyPaymentMethod,
        amount: Decimal,
        currencyCode: String
    ) async throws -> BuddyPaymentResult {
        try await paymentService.initiateEscrowPayment(
            orderID: orderID,
            method: method,
            amount: amount,
            currencyCode: currencyCode
        )
    }
}

public struct StartBuddyVoicePreChatUseCase: Sendable {
    private let voiceService: any BuddyVoicePreChatService
    public init(voiceService: any BuddyVoicePreChatService) { self.voiceService = voiceService }
    public func callAsFunction(listingID: String, ownerUserID: String) async throws -> BuddyVoicePreChatSession {
        try await voiceService.startSession(listingID: listingID, ownerUserID: ownerUserID)
    }
}

public struct EndBuddyVoicePreChatUseCase: Sendable {
    private let voiceService: any BuddyVoicePreChatService
    public init(voiceService: any BuddyVoicePreChatService) { self.voiceService = voiceService }
    public func callAsFunction(sessionID: String) async {
        await voiceService.endSession(sessionID: sessionID)
    }
}

public struct StartBuddySafetySessionUseCase: Sendable {
    private let safetyService: any BuddySafetyService
    public init(safetyService: any BuddySafetyService) { self.safetyService = safetyService }
    public func callAsFunction(orderID: String) async throws -> BuddySafetySession {
        try await safetyService.startSession(orderID: orderID)
    }
}

public struct TriggerBuddySOSUseCase: Sendable {
    private let safetyService: any BuddySafetyService
    public init(safetyService: any BuddySafetyService) { self.safetyService = safetyService }
    public func callAsFunction(sessionID: String) async throws {
        try await safetyService.triggerSOS(sessionID: sessionID)
    }
}
