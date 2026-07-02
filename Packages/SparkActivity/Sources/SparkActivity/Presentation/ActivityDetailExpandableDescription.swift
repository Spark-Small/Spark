// Module: SparkActivity — Meetup-style expandable event description.

import SparkDesignSystem
import SwiftUI

struct ActivityDetailExpandableDescription: View {
    let text: String
    let collapsedLineLimit: Int

    @State private var isExpanded = false

    init(text: String, collapsedLineLimit: Int = 4) {
        self.text = text
        self.collapsedLineLimit = collapsedLineLimit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.compactVerticalPadding) {
            if trimmedText.isEmpty {
                Text(
                    String(
                        localized: "activity.detail.about.empty",
                        defaultValue: "主办尚未添加简介。",
                        comment: "Empty description"
                    )
                )
                .font(.body)
                .foregroundStyle(.secondary)
            } else {
                Text(trimmedText)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(SparkLayoutMetrics.communityFeedBodyLineSpacing)
                    .lineLimit(isExpanded ? nil : collapsedLineLimit)
                    .fixedSize(horizontal: false, vertical: true)

                if needsReadMore {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text(
                            isExpanded
                                ? String(
                                    localized: "activity.detail.readLess",
                                    defaultValue: "收起",
                                    comment: "Collapse description"
                                )
                                : String(
                                    localized: "activity.detail.viewMore",
                                    defaultValue: "查看更多",
                                    comment: "View more description"
                                )
                        )
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(
                        isExpanded
                            ? String(
                                localized: "activity.detail.readLess.hint",
                                defaultValue: "收起活动简介",
                                comment: "Collapse hint"
                            )
                            : String(
                                localized: "activity.detail.readMore.hint",
                                defaultValue: "查看完整活动简介",
                                comment: "Expand hint"
                            )
                    )
                }
            }
        }
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var needsReadMore: Bool {
        trimmedText.count > 100 || trimmedText.components(separatedBy: .newlines).count > collapsedLineLimit
    }
}

#Preview {
    ActivityDetailExpandableDescription(
        text: String(repeating: "城郊步道轻徒步，约 8km。", count: 8)
    )
    .padding()
}
