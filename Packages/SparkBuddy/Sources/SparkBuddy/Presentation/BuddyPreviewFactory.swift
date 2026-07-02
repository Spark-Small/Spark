// Module: SparkBuddy — Shared preview factories.

import Foundation

#if DEBUG
enum BuddyPreviewFactory {
    @MainActor
    static func detailViewModel(listingID: String = "buddy_city_1") -> BuddyDetailViewModel {
        let repository = MockBuddyRepository()
        let voice = MockBuddyVoicePreChatService()
        let payment = MockBuddyPaymentService()
        let safety = MockBuddySafetyService()
        let match = MockBuddyMatchEngineService()
        return BuddyDetailViewModel(
            listingID: listingID,
            fetchDetail: FetchBuddyListingDetailUseCase(repository: repository),
            createOrder: CreateBuddyOrderUseCase(repository: repository),
            initiatePayment: InitiateBuddyEscrowPaymentUseCase(paymentService: payment),
            refreshMatch: RefreshBuddyMatchInsightUseCase(matchEngine: match),
            startVoicePreChat: StartBuddyVoicePreChatUseCase(voiceService: voice),
            endVoicePreChat: EndBuddyVoicePreChatUseCase(voiceService: voice),
            startSafetySession: StartBuddySafetySessionUseCase(safetyService: safety),
            triggerSOS: TriggerBuddySOSUseCase(safetyService: safety)
        )
    }
}
#endif
