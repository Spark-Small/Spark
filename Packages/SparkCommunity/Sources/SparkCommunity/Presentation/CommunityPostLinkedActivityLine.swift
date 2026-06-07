// Module: SparkCommunity — Linked activity metadata (feed + detail parity).

import SparkDesignSystem
import SwiftUI

struct CommunityPostLinkedActivityLine: View {
    let name: String
    let onTap: (() -> Void)?

    init(name: String, onTap: (() -> Void)? = nil) {
        self.name = name
        self.onTap = onTap
    }

    var body: some View {
        Group {
            if let onTap {
                Button(action: onTap) {
                    label
                }
                .buttonStyle(.sparkPressable)
                .accessibilityHint(
                    String(
                        localized: "community.detail.activityBanner.action",
                        defaultValue: "查看活动详情",
                        comment: "Open activity"
                    )
                )
            } else {
                label
            }
        }
        .accessibilityLabel(linkedActivityAccessibilityLabel)
    }

    private var linkedActivityAccessibilityLabel: String {
        String(
            format: String(
                localized: "community.post.linkedActivity.a11y",
                defaultValue: "关联活动：%@",
                comment: "Linked activity"
            ),
            locale: .current,
            name
        )
    }

    private var label: some View {
        Label(name, systemImage: "calendar")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Linked activity line") {
        VStack(alignment: .leading, spacing: 8) {
            CommunityPostLinkedActivityLine(
                name: String(localized: "community.mock.activity.book", defaultValue: "咖啡聊天局", comment: "Activity")
            )
            CommunityPostLinkedActivityLine(
                name: String(localized: "community.mock.activity.hike", defaultValue: "周末爬香山", comment: "Activity"),
                onTap: {}
            )
        }
        .padding()
    }
}
