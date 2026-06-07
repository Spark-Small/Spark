// Module: SparkCommunity — Topic tags below post copy, above engagement actions.

import SparkDesignSystem
import SwiftUI

/// Inline topic tags (e.g. #爬山 #周末) placed immediately after post body — not below comment actions.
struct CommunityPostTagsRow: View {
    let tags: [String]

    var body: some View {
        if !tags.isEmpty {
            Text(formattedTags)
                .font(.footnote)
                .foregroundStyle(Color.accentColor)
                .lineSpacing(SparkLayoutMetrics.communityFeedBodyLineSpacing)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(accessibilityLabel)
        }
    }

    private var formattedTags: String {
        tags.map { tag in
            let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.hasPrefix("#") ? trimmed : "#\(trimmed)"
        }
        .joined(separator: " ")
    }

    private var accessibilityLabel: String {
        let format = String(
            localized: "community.post.tags.a11y.format",
            defaultValue: "话题：%@",
            comment: "Post topic tags; %@ is tag list"
        )
        return String(format: format, locale: .current, tags.joined(separator: "、"))
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Post tags") {
        CommunityPostTagsRow(
            tags: [
                String(localized: "community.mock.tag.hike", defaultValue: "爬山", comment: "Tag"),
                String(localized: "community.mock.tag.weekend", defaultValue: "周末", comment: "Tag")
            ]
        )
        .padding()
    }
}
