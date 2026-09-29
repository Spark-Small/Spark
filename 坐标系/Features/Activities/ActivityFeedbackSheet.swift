//
//  ActivityFeedbackSheet.swift
//  坐标系
//
//  活动结束后轻量体验反馈（标签单选）。
//

import SwiftUI
import CoordinateModels

enum ActivityExperienceFeedbackCopy {
    static let sheetTitle = "这场活动体验如何？"
    static let sheetSubtitle = "选一个最符合的感受，帮助其他人做决定"
    static let skip = "跳过"
    static let submit = "提交反馈"

    static let tags = ["组织很好", "准时顺畅", "氛围有趣", "想再约一次", "一般般"]
}

struct ActivityFeedbackSheet: View {
    let activity: Activity
    var onSubmit: (String) -> Void
    var onSkip: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTag: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                Text(activity.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(ActivityExperienceFeedbackCopy.sheetSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                FlowLayoutTags(
                    tags: ActivityExperienceFeedbackCopy.tags,
                    selection: $selectedTag
                )

                Spacer(minLength: 0)
            }
            .padding(PlatformMetrics.contentInset)
            .navigationTitle(ActivityExperienceFeedbackCopy.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ActivityExperienceFeedbackCopy.skip) {
                        onSkip?()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActivityExperienceFeedbackCopy.submit) {
                        if let selectedTag {
                            onSubmit(selectedTag)
                        }
                        dismiss()
                    }
                    .disabled(selectedTag == nil)
                    .fontWeight(.semibold)
                }
            }
        }
        .platformSheet(.confirm)
    }
}

/// 简单流式标签布局
private struct FlowLayoutTags: View {
    let tags: [String]
    @Binding var selection: String?

    var body: some View {
        FlexibleTagGrid(tags: tags, selection: $selection)
    }
}

private struct FlexibleTagGrid: View {
    let tags: [String]
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
            ForEach(rowedTags, id: \.self) { row in
                HStack(spacing: PlatformMetrics.cardInfoSpacing) {
                    ForEach(row, id: \.self) { tag in
                        tagButton(tag)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var rowedTags: [[String]] {
        var rows: [[String]] = [[]]
        let maxPerRow = 2
        for tag in tags {
            if rows[rows.count - 1].count >= maxPerRow {
                rows.append([tag])
            } else {
                rows[rows.count - 1].append(tag)
            }
        }
        return rows
    }

    private func tagButton(_ tag: String) -> some View {
        let isSelected = selection == tag
        return Button {
            selection = tag
        } label: {
            Text(tag)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, PlatformMetrics.formRowVerticalPadding)
                .padding(.vertical, PlatformMetrics.hairlineSpacing * 2)
                .frame(maxWidth: .infinity)
                .foregroundStyle(isSelected ? PlatformAction.brandAccent : .primary)
                .modifier(FeedbackTagChrome(isSelected: isSelected))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct FeedbackTagChrome: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let isSelected: Bool

    func body(content: Content) -> some View {
        if isSelected {
            content.background(PlatformAction.brandAccent.opacity(0.14), in: Capsule())
        } else if reduceTransparency {
            content.background(Color(.secondarySystemBackground), in: Capsule())
        } else {
            content.background(.thinMaterial, in: Capsule())
        }
    }
}
