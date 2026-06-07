// Module: SparkProfileTests — Profile summary model coverage.

import SparkProfile
import SparkTrust
import Testing

struct ProfileSummaryTests {
    @Test func summaryWrapsTrustProfile() {
        let profile = TrustProfile(totalScore: 72, completedLevels: [.phone])
        let summary = ProfileSummary(trustProfile: profile)
        #expect(summary.trustProfile.totalScore == 72)
    }
}
