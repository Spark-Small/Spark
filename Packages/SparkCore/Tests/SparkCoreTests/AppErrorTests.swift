// Module: SparkCoreTests — Core type unit tests.

import SparkCore
import Testing

struct AppErrorTests {
    @Test func networkUnavailableHasDescription() {
        let error = AppError.networkUnavailable
        #expect(error.errorDescription != nil)
    }

    @Test func retryPolicyDelaysIncrease() {
        let policy = RetryPolicy(maxAttempts: 4, baseDelaySeconds: 1, multiplier: 2)
        #expect(policy.delayBeforeAttempt(0) == 0)
        #expect(policy.delayBeforeAttempt(1) == 1)
        #expect(policy.delayBeforeAttempt(2) == 2)
    }
}
