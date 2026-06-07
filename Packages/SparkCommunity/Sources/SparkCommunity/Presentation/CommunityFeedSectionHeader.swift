// Module: SparkCommunity — Section header for tab feed.

import SparkDesignSystem
import SwiftUI

struct CommunityFeedSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.feedSectionHeaderVerticalPadding)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(title)
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Feed section header") {
        CommunityFeedSectionHeader(
            title: String(localized: "community.home.segment.feed", defaultValue: "动态", comment: "Feed")
        )
    }
}
