// Module: SparkCommunity — Prompt to explore communities when user has none joined.

import SparkDesignSystem
import SwiftUI

struct CommunityJoinPromptCard: View {
    let onExplore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            Text(
                String(
                    localized: "community.joinPrompt.title",
                    defaultValue: "加入活动社区",
                    comment: "Join community prompt title"
                )
            )
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            Text(
                String(
                    localized: "community.joinPrompt.subtitle",
                    defaultValue: "查看局后随拍和与你有关的熟人动态",
                    comment: "Join community prompt subtitle"
                )
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            Button(action: onExplore) {
                Text(
                    String(
                        localized: "community.explore.title",
                        defaultValue: "探索社区",
                        comment: "Explore communities title"
                    )
                )
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, SparkLayoutMetrics.communityCarouselRowTopInset)
        }
        .padding(SparkLayoutMetrics.standardHorizontalPadding)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: SparkLayoutMetrics.sparkCardCornerRadius))
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Join prompt") {
        CommunityJoinPromptCard(onExplore: {})
            .padding()
    }
}
