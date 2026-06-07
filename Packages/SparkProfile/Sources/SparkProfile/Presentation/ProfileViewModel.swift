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

    public private(set) var profile: TrustProfile?
    public private(set) var loadState: LoadState = .idle

    private let fetchTrustProfile: FetchTrustProfileUseCase

    public init(trustRepository: any TrustRepository) {
        fetchTrustProfile = FetchTrustProfileUseCase(repository: trustRepository)
    }

    public func load() async {
        loadState = .loading
        do {
            profile = try await fetchTrustProfile()
            loadState = .loaded
        } catch is CancellationError {
            return
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }
}
