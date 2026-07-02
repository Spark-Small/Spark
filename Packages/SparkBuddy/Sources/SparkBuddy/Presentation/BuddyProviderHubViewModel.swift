// Module: SparkBuddy — Provider hub status for Profile rows.

import Foundation
import OSLog
import SparkCore

@MainActor
@Observable
public final class BuddyProviderHubViewModel {
    private let logger = SparkLog.logger(category: "BuddyProviderHub")

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(BuddyProviderStatus)
        case failure(String)
    }

    private(set) var loadState: LoadState = .idle
    private let fetchStatus: any FetchBuddyProviderStatusUseCaseProtocol

    public init(fetchStatus: any FetchBuddyProviderStatusUseCaseProtocol) {
        self.fetchStatus = fetchStatus
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await reload()
    }

    func reload() async {
        loadState = .loading
        do {
            let status = try await fetchStatus()
            BuddyTelemetry.providerHubOpened(state: status.state.rawValue)
            loadState = .loaded(status)
        } catch is CancellationError {
            return
        } catch {
            logger.error("Provider hub load failed: \(error.localizedDescription, privacy: .public)")
            loadState = .failure(AppError(buddyUnderlying: error).localizedDescription)
        }
    }
}
