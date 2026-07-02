// Module: SparkCoreTests — Shared UGC moderation tokens.

import Testing
@testable import SparkCore

struct UGCModerationTests {
    @Test func detectsBlockedToken() {
        #expect(UGCModeration.firstViolation(in: "这里有赌博信息") == "赌博")
    }

    @Test func allowsCleanText() {
        #expect(UGCModeration.firstViolation(in: "正常的社区讨论") == nil)
    }
}
