// Module: SparkTrust — Verification wizard state.

import Foundation
import Observation

@MainActor
@Observable
public final class TrustVerificationViewModel {
    public private(set) var profile: TrustProfile?
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let fetchProfile: FetchTrustProfileUseCase
    private let verifyLevel: VerifyTrustLevelUseCase
    public var onCompleted: (() -> Void)?

    public init(repository: any TrustRepository) {
        fetchProfile = FetchTrustProfileUseCase(repository: repository)
        verifyLevel = VerifyTrustLevelUseCase(repository: repository)
    }

    public func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            profile = try await fetchProfile()
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func verify(_ level: TrustLevel) async {
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await verifyLevel(level)
            if profile?.nextMVPPendingLevel == nil {
                onCompleted?()
            }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
