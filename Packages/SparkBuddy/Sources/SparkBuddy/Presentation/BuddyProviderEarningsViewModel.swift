// Module: SparkBuddy — Gated provider earnings state.

import Foundation
import OSLog
import SparkCore

@MainActor
@Observable
public final class BuddyProviderEarningsViewModel {
    enum ViewState: Equatable {
        case loading
        case loaded(BuddyProviderEarnings, [BuddyProviderOrder])
        case failure(String)
    }

    private(set) var state: ViewState = .loading
    private let fetchEarnings: any FetchBuddyProviderEarningsUseCaseProtocol
    private let fetchOrders: any FetchBuddyProviderOrdersUseCaseProtocol
    private let logger = SparkLog.logger(category: "BuddyProviderEarnings")

    public init(
        fetchEarnings: any FetchBuddyProviderEarningsUseCaseProtocol,
        fetchOrders: any FetchBuddyProviderOrdersUseCaseProtocol
    ) {
        self.fetchEarnings = fetchEarnings
        self.fetchOrders = fetchOrders
    }

    func load() async {
        state = .loading
        do {
            async let earnings = fetchEarnings()
            async let orders = fetchOrders()
            state = .loaded(try await earnings, try await orders)
        } catch is CancellationError {
            return
        } catch {
            logger.error("Provider earnings load failed: \(error.localizedDescription, privacy: .public)")
            state = .failure(AppError(buddyUnderlying: error).localizedDescription)
        }
    }
}
