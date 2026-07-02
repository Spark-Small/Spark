// Module: SparkBuddy — Listing detail state.

import Foundation
import OSLog
import SparkCore
import SparkPayments

@MainActor
@Observable
public final class BuddyDetailViewModel {
    private let logger = SparkLog.logger(category: "BuddyDetail")

    enum ViewState: Equatable {
        case loading
        case loaded(BuddyListing)
        case failure(String)
    }

    enum BookingState: Equatable {
        case idle
        case submitting
        case success(BuddyOrderConfirmation)
        case failure(String)
    }

    private(set) var state: ViewState = .loading
    private(set) var bookingState: BookingState = .idle
    private(set) var activeVoiceSession: BuddyVoicePreChatSession?
    private(set) var activeSafetySession: BuddySafetySession?
    private(set) var refreshedMatchInsight: BuddyMatchInsight?

    var isBookingSheetPresented = false
    var isPreChatSheetPresented = false
    var isSafetyCenterPresented = false
    var selectedPackageID: String?
    var selectedPaymentMethod: BuddyPaymentMethod = .wechatPay
    var scheduledDate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now

    private let listingID: String
    private let fetchDetail: any FetchBuddyListingDetailUseCaseProtocol
    private let createOrder: any CreateBuddyOrderUseCaseProtocol
    private let initiatePayment: any InitiateBuddyEscrowPaymentUseCaseProtocol
    private let refreshMatch: any RefreshBuddyMatchInsightUseCaseProtocol
    private let startVoicePreChat: StartBuddyVoicePreChatUseCase
    private let endVoicePreChat: EndBuddyVoicePreChatUseCase
    private let startSafetySession: StartBuddySafetySessionUseCase
    private let triggerSOS: TriggerBuddySOSUseCase

    public init(
        listingID: String,
        fetchDetail: any FetchBuddyListingDetailUseCaseProtocol,
        createOrder: any CreateBuddyOrderUseCaseProtocol,
        initiatePayment: any InitiateBuddyEscrowPaymentUseCaseProtocol,
        refreshMatch: any RefreshBuddyMatchInsightUseCaseProtocol,
        startVoicePreChat: StartBuddyVoicePreChatUseCase,
        endVoicePreChat: EndBuddyVoicePreChatUseCase,
        startSafetySession: StartBuddySafetySessionUseCase,
        triggerSOS: TriggerBuddySOSUseCase
    ) {
        self.listingID = listingID
        self.fetchDetail = fetchDetail
        self.createOrder = createOrder
        self.initiatePayment = initiatePayment
        self.refreshMatch = refreshMatch
        self.startVoicePreChat = startVoicePreChat
        self.endVoicePreChat = endVoicePreChat
        self.startSafetySession = startSafetySession
        self.triggerSOS = triggerSOS
    }

    func load() async {
        state = .loading
        do {
            let listing = try await fetchDetail(id: listingID)
            BuddyTelemetry.listingDetailOpened(listingID: listingID)
            if selectedPackageID == nil {
                selectedPackageID = listing.packages.first?.id
            }
            state = .loaded(listing)
        } catch is CancellationError {
            return
        } catch {
            logger.error(
                "Buddy detail fetch failed id=\(self.listingID, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            state = .failure(AppError(buddyUnderlying: error).localizedDescription)
        }
    }

    func presentBooking(for listing: BuddyListing) {
        if selectedPackageID == nil {
            selectedPackageID = listing.packages.first?.id
        }
        bookingState = .idle
        isBookingSheetPresented = true
    }

    func presentPreChat() {
        BuddyTelemetry.preChatOpened(listingID: listingID)
        isPreChatSheetPresented = true
    }

    func presentSafetyCenter() {
        BuddyTelemetry.safetyCenterOpened(listingID: listingID)
        isSafetyCenterPresented = true
    }

    func selectPaymentMethod(_ method: BuddyPaymentMethod) {
        selectedPaymentMethod = method
        BuddyTelemetry.paymentMethodSelected(method: method.rawValue)
    }

    func refreshMatchInsight() async {
        do {
            refreshedMatchInsight = try await refreshMatch(listingID: listingID)
        } catch {
            logger.warning("Match refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func startPreChatSession(for listing: BuddyListing) async {
        do {
            activeVoiceSession = try await startVoicePreChat(
                listingID: listing.id,
                ownerUserID: listing.ownerUserID
            )
        } catch {
            logger.error("Voice pre-chat failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func endPreChatSession() async {
        guard let session = activeVoiceSession else { return }
        await endVoicePreChat(sessionID: session.id)
        activeVoiceSession = nil
    }

    func startSafetyEscort(orderID: String) async {
        do {
            activeSafetySession = try await startSafetySession(orderID: orderID)
        } catch {
            logger.error("Safety session failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func triggerSOSAlert() async {
        guard let session = activeSafetySession else { return }
        do {
            try await triggerSOS(sessionID: session.id)
        } catch {
            logger.error("SOS trigger failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func submitBooking(for listing: BuddyListing) async {
        guard let packageID = selectedPackageID ?? listing.packages.first?.id else {
            bookingState = .failure(
                String(
                    localized: "buddy.booking.error.noPackage",
                    defaultValue: "请选择服务套餐",
                    comment: "No package selected"
                )
            )
            return
        }
        BuddyTelemetry.bookingStarted(listingID: listing.id, packageID: packageID)
        bookingState = .submitting
        do {
            let package = listing.packages.first(where: { $0.id == packageID }) ?? listing.packages.first
            let draft = BuddyOrderDraft(
                listingID: listing.id,
                packageID: packageID,
                scheduledAt: scheduledDate,
                paymentMethod: selectedPaymentMethod
            )
            let confirmation = try await createOrder(draft: draft)
            if SparkFeatureFlags.isBuddyEscrowPaymentEnabled, let package {
                _ = try await initiatePayment(
                    orderID: confirmation.id,
                    method: selectedPaymentMethod,
                    amount: package.priceAmount,
                    currencyCode: package.priceCurrencyCode
                )
            }
            await startSafetyEscort(orderID: confirmation.id)
            BuddyTelemetry.bookingCompleted(orderID: confirmation.id)
            bookingState = .success(confirmation)
        } catch is CancellationError {
            bookingState = .idle
        } catch {
            logger.error("Buddy booking failed: \(error.localizedDescription, privacy: .public)")
            bookingState = .failure(AppError(buddyUnderlying: error).localizedDescription)
        }
    }

    func resetBookingState() {
        bookingState = .idle
    }

    func matchInsight(for listing: BuddyListing) -> BuddyMatchInsight? {
        refreshedMatchInsight ?? listing.matchInsight
    }
}
