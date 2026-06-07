// Module: SparkTrustTests

import SparkTrust
import Testing

@Suite struct TrustProfileTests {
    @Test func mockProfileHasPhoneLevel() async {
        let repo = MockTrustRepository(initialCompleted: [.phone])
        let profile = try? await repo.fetchProfile()
        #expect(profile?.completedLevels.contains(.phone) == true)
    }
}
