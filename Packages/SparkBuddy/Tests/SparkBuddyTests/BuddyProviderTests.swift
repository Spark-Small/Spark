// Module: SparkBuddyTests — Provider gating and application.

import SparkBuddy
import Testing

struct BuddyProviderTests {
    @Test func earningsRequiresApproval() async {
        let repository = MockBuddyRepository()
        await repository.resetProviderStateForTesting()
        await #expect(throws: BuddyError.self) {
            _ = try await repository.fetchProviderEarnings()
        }
    }

    @Test func applicationApprovesInMock() async throws {
        let repository = MockBuddyRepository()
        await repository.resetProviderStateForTesting()
        let draft = BuddyProviderApplicationDraft(
            displayName: "测试陪玩",
            city: "成都",
            serviceCategory: .food,
            bio: "熟悉本地美食与夜生活路线规划。",
            capabilityTags: ["美食达人"]
        )
        let status = try await repository.submitProviderApplication(draft)
        #expect(status.canAccessEarnings)
        let earnings = try await repository.fetchProviderEarnings()
        #expect(earnings.availableBalance > 0)
    }

    @Test func invalidApplicationRejected() async {
        let repository = MockBuddyRepository()
        await repository.resetProviderStateForTesting()
        let draft = BuddyProviderApplicationDraft(
            displayName: "",
            city: "",
            serviceCategory: .cityWalk,
            bio: "短",
            capabilityTags: []
        )
        await #expect(throws: BuddyError.self) {
            _ = try await repository.submitProviderApplication(draft)
        }
    }
}
