// Module: SparkActivity — App Store Today–style stage tag on activity card hero.

import SparkDesignSystem
import SwiftUI

/// Top-leading editorial badge on activity cover cards.
struct ActivityStageStatusBadge: View {
    let status: ActivityListStageStatus
    var cornerRadius: CGFloat = SparkLayoutMetrics.activityCardHeroCornerRadius

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, SparkLayoutMetrics.activityStageBadgeHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.activityStageBadgeVerticalPadding)
            .background(status.accentColor, in: badgeShape)
            .accessibilityLabel(status.label)
    }

    /// Flush with card top-leading corner; inner corners stay softly rounded.
    private var badgeShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: cornerRadius,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: SparkLayoutMetrics.activityStageBadgeInnerCornerRadius,
            topTrailingRadius: SparkLayoutMetrics.activityStageBadgeInnerCornerRadius,
            style: .continuous
        )
    }
}

#Preview("Stage badges") {
    VStack(alignment: .leading, spacing: 16) {
        ActivityStageStatusBadge(status: .registrationOpen)
        ActivityStageStatusBadge(status: .full)
        ActivityStageStatusBadge(status: .lifecycle(.ended))
        ActivityStageStatusBadge(status: .rsvp(.going))
    }
    .padding()
    .background(.quaternary)
}
