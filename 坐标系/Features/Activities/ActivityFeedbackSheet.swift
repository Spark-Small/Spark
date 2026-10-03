//
//  ActivityFeedbackSheet.swift
//  坐标系
//
//  活动结束后轻量体验反馈（标签单选）。
//

import SwiftUI
import CoordinateModels

struct ActivityFeedbackSheet: View {
    let activity: Activity
    var onSubmit: (String) -> Void
    var onSkip: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTag: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(activity.title)
                        .font(.headline)
                        .lineLimit(2)
                        .accessibilityAddTraits(.isHeader)
                    Text(ActivityExperienceFeedbackCopy.sheetSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    FlexibleTagGrid(
                        tags: ActivityExperienceFeedbackCopy.tags,
                        selection: $selectedTag
                    )
                } footer: {
                    if selectedTag == nil {
                        Text(ActivityExperienceFeedbackCopy.selectTagHint)
                    }
                }
            }
            .navigationTitle(ActivityExperienceFeedbackCopy.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .platformSheetCancellationToolbar(ActivityExperienceFeedbackCopy.skip) {
                onSkip?()
                dismiss()
            }
            .platformSheetConfirmationToolbar(
                ActivityExperienceFeedbackCopy.submit,
                isEnabled: selectedTag != nil,
                emphasizesWhenEnabled: true
            ) {
                if let selectedTag {
                    onSubmit(selectedTag)
                }
                dismiss()
            }
        }
        .platformSheet(.confirm)
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
                .padding(.horizontal, PlatformMetrics.chipPaddingHorizontalRegular)
                .padding(.vertical, PlatformMetrics.chipPaddingVerticalRegular)
                .frame(maxWidth: .infinity)
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .platformMaterialTagChrome(isSelected: isSelected)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
