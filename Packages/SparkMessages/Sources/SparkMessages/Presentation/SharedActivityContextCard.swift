// Module: SparkMessages — Inline shared-activity context inside conversation list.

import SparkDesignSystem
import SwiftUI

struct SharedActivityContextCard: View {
    let activity: InboxActivitySummary
    let contextLabel: String
    var showsCountdown: Bool = false
    var onOpen: ((String) -> Void)?

    var body: some View {
        Button {
            onOpen?(activity.id)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .sparkGlassSurface(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(contextLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(activity.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    if showsCountdown {
                        Text(activity.countdownText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .sparkGlassSurface(RoundedRectangle.sparkCard)
        }
        .buttonStyle(.sparkPressable)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityHint(
            String(
                localized: "messages.sharedActivity.open.hint",
                defaultValue: "打开活动详情",
                comment: "Open shared activity"
            )
        )
    }
}
