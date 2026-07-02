import Testing
@testable import SparkActivity

@Suite struct ActivityFeedPremiumLockTests {
    @Test func firstRowStaysUnlockedWhenPaywallEnabled() {
        #expect(
            !ActivityFeedPremiumLock.isRowLocked(
                at: 0,
                isPaywallEnabled: true,
                hasFullFeedAccess: false
            )
        )
    }

    @Test func secondRowLockedWithoutFullFeedAccess() {
        #expect(
            ActivityFeedPremiumLock.isRowLocked(
                at: 1,
                isPaywallEnabled: true,
                hasFullFeedAccess: false
            )
        )
    }

    @Test func allRowsUnlockedWhenPaywallDisabled() {
        #expect(
            !ActivityFeedPremiumLock.isRowLocked(
                at: 3,
                isPaywallEnabled: false,
                hasFullFeedAccess: false
            )
        )
    }

    @Test func allRowsUnlockedWithFullFeedAccess() {
        #expect(
            !ActivityFeedPremiumLock.isRowLocked(
                at: 2,
                isPaywallEnabled: true,
                hasFullFeedAccess: true
            )
        )
    }
}
