// Module: SparkDesignSystemTests

import SparkDesignSystem
import Testing

@Suite(.serialized)
@MainActor
struct DesignSystemSmokeTests {
    @Test func placeholderCardBuilds() {
        _ = SparkPlaceholderCard(title: "A", subtitle: "B", systemImage: "star")
    }
}
