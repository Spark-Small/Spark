// Module: SparkBuddy — UseCase protocols for ViewModel testability.

import Foundation

public protocol FetchBuddyListingsUseCaseProtocol: Sendable {
    func callAsFunction(query: BuddyListQuery) async throws -> BuddyListPage
}

public protocol FetchBuddyListingDetailUseCaseProtocol: Sendable {
    func callAsFunction(id: String) async throws -> BuddyListing
}

public protocol FetchBuddyReviewsUseCaseProtocol: Sendable {
    func callAsFunction(query: BuddyReviewQuery) async throws -> BuddyReviewPage
}

public protocol CreateBuddyOrderUseCaseProtocol: Sendable {
    func callAsFunction(draft: BuddyOrderDraft) async throws -> BuddyOrderConfirmation
}

public protocol FetchBuddyProviderStatusUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> BuddyProviderStatus
}

public protocol SubmitBuddyProviderApplicationUseCaseProtocol: Sendable {
    func callAsFunction(draft: BuddyProviderApplicationDraft) async throws -> BuddyProviderStatus
}

public protocol FetchBuddyProviderEarningsUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> BuddyProviderEarnings
}

public protocol FetchBuddyProviderOrdersUseCaseProtocol: Sendable {
    func callAsFunction() async throws -> [BuddyProviderOrder]
}

public protocol RefreshBuddyMatchInsightUseCaseProtocol: Sendable {
    func callAsFunction(listingID: String) async throws -> BuddyMatchInsight
}

public protocol InitiateBuddyEscrowPaymentUseCaseProtocol: Sendable {
    func callAsFunction(
        orderID: String,
        method: BuddyPaymentMethod,
        amount: Decimal,
        currencyCode: String
    ) async throws -> BuddyPaymentResult
}
