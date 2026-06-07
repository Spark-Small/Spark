// Module: SparkCommunity — Section header for tab feed.

import SparkDesignSystem
import SwiftUI

struct CommunityFeedSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(title)
    }
}

#Preview {
    CommunityFeedSectionHeader(title: "热门讨论")
}
