//
//  ActivityDetailContentBlocks.swift
//  坐标系
//
//  活动详情内容块：时间轴、费用、装备、注意事项、可折叠段。
//

import SwiftUI
import CoordinateModels

// MARK: - Content blocks

/// 详情有序步骤：统一用 SF Symbols 空心序号圆（与须知 / 准备一致）
enum ActivityDetailStepSymbol {
    static func systemName(_ step: Int) -> String {
        (1...50).contains(step) ? "\(step).circle" : "circle"
    }
}

/// 详情正文行：图标 + 内容，系统 HStack 默认间距
private struct ActivityDetailSectionRow<Icon: View, Content: View>: View {
    var alignment: VerticalAlignment = .top
    @ViewBuilder var icon: () -> Icon
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(alignment: alignment) {
            icon()
            content()
        }
        .font(.body)
    }
}

struct ActivityDetailTimelineCard: View {
    let items: [ActivityDetailTimelineItem]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let step = index + 1
                ActivityDetailSectionRow {
                    Image(systemName: ActivityDetailStepSymbol.systemName(step))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                } content: {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(item.time)
                                .monospacedDigit()
                            Text(item.title)
                        }
                        .foregroundStyle(.primary)
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityLabel("\(step). \(item.time)，\(item.title)。\(item.detail)")
            }
        }
    }
}

struct ActivityDetailFeeCard: View {
    let included: [ActivityDetailChecklistItem]
    let excluded: [ActivityDetailChecklistItem]
    let refundNotes: [String]

    var body: some View {
        VStack(alignment: .leading) {
            if !included.isEmpty {
                checklistGroup(title: "费用包含", items: included)
            }
            if !excluded.isEmpty {
                checklistGroup(title: "费用不含", items: excluded)
            }
            if !refundNotes.isEmpty {
                VStack(alignment: .leading) {
                    Text("变更与退款")
                        .font(.body)
                        .foregroundStyle(.primary)
                    ForEach(Array(refundNotes.enumerated()), id: \.offset) { _, note in
                        ActivityDetailSectionRow {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        } content: {
                            Text(note)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private func checklistGroup(title: String, items: [ActivityDetailChecklistItem]) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.body)
                .foregroundStyle(.primary)
            ForEach(items) { item in
                ActivityDetailSectionRow {
                    if item.included {
                        Image(systemName: "checkmark.circle.fill")
                            .platformSymbolStyle(.status(PlatformStatus.success))
                    } else {
                        Image(systemName: "circle")
                            .platformSymbolStyle(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                } content: {
                    Text(item.text)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct ActivityDetailGearGrid: View {
    let items: [ActivityDetailGearItem]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(items) { item in
                ActivityDetailSectionRow {
                    Image(systemName: item.systemImage)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                } content: {
                    VStack(alignment: .leading) {
                        Text(item.title)
                            .foregroundStyle(.primary)
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

struct ActivityDetailNumberedNotes: View {
    let notes: [String]

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(notes.enumerated()), id: \.offset) { index, note in
                let step = index + 1
                ActivityDetailSectionRow {
                    Image(systemName: ActivityDetailStepSymbol.systemName(step))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                } content: {
                    Text(note)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityLabel("\(step). \(note)")
            }
        }
    }
}

/// 活动详情可折叠蓝图分区（默认收起，摘要先行）
struct ActivityDetailCollapsibleSection<Content: View>: View {
    let title: String
    let summary: String
    @Binding var isExpanded: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content()
                .padding(.top, PlatformMetrics.cardInfoSpacing)
        } label: {
            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(title)
                    .font(.headline)
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, PlatformMetrics.hairlineSpacing)
        }
    }
}

