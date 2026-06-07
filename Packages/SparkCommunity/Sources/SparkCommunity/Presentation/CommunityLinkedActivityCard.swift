// Module: SparkCommunity — Linked activity card on recap posts.

import SparkDesignSystem
import SwiftUI

struct CommunityLinkedActivityCard: View {
    let title: String
    let scheduleLine: String?
    let onOpenActivity: () -> Void

    var body: some View {
        Button(action: onOpenActivity) {
            VStack(alignment: .leading, spacing: 6) {
                Label(
                    String(
                        localized: "community.recap.linkedActivity",
                        defaultValue: "关联活动",
                        comment: "Linked activity label"
                    ),
                    systemImage: "calendar"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                if let scheduleLine, !scheduleLine.isEmpty {
                    Text(scheduleLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(
                    String(
                        localized: "community.recap.openActivity",
                        defaultValue: "查看活动 · 报名下一场",
                        comment: "Open linked activity"
                    )
                )
                .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .sparkGlassSurface(RoundedRectangle.sparkCard)
        }
        .buttonStyle(.sparkPressable)
        .accessibilityLabel(title)
        .accessibilityHint(
            String(
                localized: "community.recap.openActivity.hint",
                defaultValue: "打开活动详情",
                comment: "Linked activity a11y hint"
            )
        )
    }
}

#Preview {
    CommunityLinkedActivityCard(
        title: "玉林咖啡聊天局",
        scheduleLine: "周六 · 玉林西路",
        onOpenActivity: {}
    )
    .padding()
}
