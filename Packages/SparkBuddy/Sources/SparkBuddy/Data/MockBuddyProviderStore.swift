// Module: SparkBuddy — In-memory provider approval state for Mock backend.

import Foundation

actor MockBuddyProviderStore {
    static let shared = MockBuddyProviderStore()

    private var status = BuddyProviderStatus(state: .none)
    private var applicationDraft: BuddyProviderApplicationDraft?

    func currentStatus() -> BuddyProviderStatus {
        status
    }

    func submit(_ draft: BuddyProviderApplicationDraft) -> BuddyProviderStatus {
        applicationDraft = draft
        let now = Date()
        // REASONING: Mock auto-approves so engineers can reach earnings UI without admin tooling.
        status = BuddyProviderStatus(state: .approved, submittedAt: now, reviewedAt: now)
        return status
    }

    func reset() {
        status = BuddyProviderStatus(state: .none)
        applicationDraft = nil
    }
}
