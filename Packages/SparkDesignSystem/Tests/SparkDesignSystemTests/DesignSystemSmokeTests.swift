// Module: SparkDesignSystemTests

import SparkDesignSystem
import Testing

@Suite(.serialized)
@MainActor
struct DesignSystemSmokeTests {
    @Test func placeholderCardBuilds() {
        _ = SparkPlaceholderCard(title: "A", subtitle: "B", systemImage: "star")
    }

    @Test func layoutMetricsMatchTabScreensSpec() {
        #expect(SparkLayoutMetrics.standardHorizontalPadding == 16)
        #expect(SparkLayoutMetrics.minimumTouchTarget == 44)
        #expect(SparkLayoutMetrics.sparkCardCornerRadius == 20)
        #expect(SparkLayoutMetrics.inboxModuleInnerPadding == 14)
        #expect(SparkLayoutMetrics.actionCardInnerPadding == SparkLayoutMetrics.inboxModuleInnerPadding)
        #expect(SparkLayoutMetrics.matchCardMaxWidth == 420)
    }
}
