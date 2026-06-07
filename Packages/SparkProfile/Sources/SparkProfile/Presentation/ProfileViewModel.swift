// Module: SparkProfile — Profile tab state.

import Foundation
import Observation
import SparkTrust

@MainActor
@Observable
public final class ProfileViewModel {
    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failure(String)
    }

    public private(set) var summary: ProfileSummary?
    public private(set) var loadState: LoadState = .idle

    public var profile: TrustProfile? { summary?.trustProfile }

    private let fetchProfileSummary: any FetchProfileSummaryUseCaseProtocol

    public init(fetchProfileSummary: any FetchProfileSummaryUseCaseProtocol) {
        self.fetchProfileSummary = fetchProfileSummary
    }

    public convenience init(trustRepository: any TrustRepository) {
        self.init(fetchProfileSummary: FetchProfileSummaryUseCase(trustRepository: trustRepository))
    }

    public func load() async {
        loadState = .loading
        do {
            summary = try await fetchProfileSummary()
            loadState = .loaded
        } catch is CancellationError {
            return
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }
}
