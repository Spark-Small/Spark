// Module: SparkBuddy — ViewModel factory; keeps Repository out of SwiftUI Views.

import Foundation

public struct BuddyCoordinator: Sendable {
    private let repository: any BuddyRepository
    private let voicePreChat: any BuddyVoicePreChatService
    private let payment: any BuddyPaymentService
    private let safety: any BuddySafetyService
    private let matchEngine: any BuddyMatchEngineService

    public init(
        repository: any BuddyRepository,
        voicePreChat: any BuddyVoicePreChatService = MockBuddyVoicePreChatService(),
        payment: any BuddyPaymentService = MockBuddyPaymentService(),
        safety: any BuddySafetyService = MockBuddySafetyService(),
        matchEngine: any BuddyMatchEngineService = MockBuddyMatchEngineService()
    ) {
        self.repository = repository
        self.voicePreChat = voicePreChat
        self.payment = payment
        self.safety = safety
        self.matchEngine = matchEngine
    }

    @MainActor
    public func makeBrowseViewModel() -> BuddyViewModel {
        BuddyViewModel(fetchListings: FetchBuddyListingsUseCase(repository: repository))
    }

    @MainActor
    public func makeDetailViewModel(listingID: String) -> BuddyDetailViewModel {
        BuddyDetailViewModel(
            listingID: listingID,
            fetchDetail: FetchBuddyListingDetailUseCase(repository: repository),
            createOrder: CreateBuddyOrderUseCase(repository: repository),
            initiatePayment: InitiateBuddyEscrowPaymentUseCase(paymentService: payment),
            refreshMatch: RefreshBuddyMatchInsightUseCase(matchEngine: matchEngine),
            startVoicePreChat: StartBuddyVoicePreChatUseCase(voiceService: voicePreChat),
            endVoicePreChat: EndBuddyVoicePreChatUseCase(voiceService: voicePreChat),
            startSafetySession: StartBuddySafetySessionUseCase(safetyService: safety),
            triggerSOS: TriggerBuddySOSUseCase(safetyService: safety)
        )
    }

    @MainActor
    public func makeProviderHubViewModel() -> BuddyProviderHubViewModel {
        BuddyProviderHubViewModel(
            fetchStatus: FetchBuddyProviderStatusUseCase(repository: repository)
        )
    }

    @MainActor
    public func makeProviderApplicationViewModel() -> BuddyProviderApplicationViewModel {
        BuddyProviderApplicationViewModel(
            submitApplication: SubmitBuddyProviderApplicationUseCase(repository: repository)
        )
    }

    @MainActor
    public func makeProviderEarningsViewModel() -> BuddyProviderEarningsViewModel {
        BuddyProviderEarningsViewModel(
            fetchEarnings: FetchBuddyProviderEarningsUseCase(repository: repository),
            fetchOrders: FetchBuddyProviderOrdersUseCase(repository: repository)
        )
    }

    public func fetchRecommendedListing(serviceFilter: BuddyServiceFilter) async -> BuddyCrossRecommendation? {
        guard serviceFilter != .all else { return nil }
        let query = BuddyListQuery(
            serviceFilter: serviceFilter,
            billingFilter: .all,
            cursor: nil
        )
        guard let page = try? await repository.fetchListings(query: query) else { return nil }
        guard let listing = page.items.first(where: \.isVerified) ?? page.items.first else { return nil }
        return BuddyCrossRecommendation(
            listingID: listing.id,
            title: listing.displayName,
            subtitle: BuddyFormatting.listRatingLine(
                rating: listing.rating,
                completedOrderCount: listing.completedOrderCount,
                reviewCount: listing.reviewCount
            ) ?? listing.headline
        )
    }

    public func fetchRecommendedListing(forActivityCategory category: String) async -> BuddyCrossRecommendation? {
        guard let serviceFilter = BuddyActivityCategoryBridge.serviceFilter(forActivityCategory: category) else {
            return nil
        }
        return await fetchRecommendedListing(serviceFilter: serviceFilter)
    }
}
