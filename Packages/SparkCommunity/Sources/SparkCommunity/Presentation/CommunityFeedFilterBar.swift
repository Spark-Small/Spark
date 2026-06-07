// Module: SparkCommunity — Feed segment picker (Nexus W5).

import SwiftUI

struct CommunityFeedFilterBar: View {
    @Binding var selectedFilter: CommunityFeedFilter

    var body: some View {
        Picker(
            String(localized: "community.filter.a11y", defaultValue: "帖子筛选", comment: "Feed filter"),
            selection: $selectedFilter
        ) {
            ForEach(CommunityFeedFilter.allCases) { filter in
                Text(filter.localizedTitle).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityLabel(
            String(localized: "community.filter.a11y", defaultValue: "帖子筛选", comment: "Feed filter")
        )
    }
}

#Preview {
    CommunityFeedFilterBar(selectedFilter: .constant(.all))
}
