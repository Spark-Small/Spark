//
//  TrustComponents.swift
//  坐标系
//
//  行为信用 UI：对齐设置 / 会员页的 Form + LabeledContent / Label。
//  规范见 Docs/TrustBehaviorModel.md §6。
//

import Charts
import SwiftUI
import CoordinateModels

// MARK: - Level (公开档案行)

struct TrustLevelStrip: View {
    let level: TrustLevel

    var body: some View {
        Label(level.title, systemImage: level.systemImage)
            .font(.body)
            .platformContentSymbolStyle()
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(level.title)
    }
}

// MARK: - Axis (private self-check)

struct TrustAxisBars: View {
    let axes: TrustAxisScores

    private var chartRows: [(label: String, value: Double)] {
        TrustAxisScores.labels.map { keyPath, title in
            (title, axes[keyPath: keyPath])
        }
    }

    var body: some View {
        Chart(chartRows, id: \.label) { row in
            BarMark(
                x: .value("分数", row.value),
                y: .value("维度", row.label)
            )
            .foregroundStyle(by: .value("维度", row.label))
            .annotation(position: .trailing, alignment: .trailing) {
                Text("\(Int(row.value.rounded()))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .chartLegend(.hidden)
        .chartXScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: [0, 50, 100])
        }
        .frame(height: CGFloat(chartRows.count) * 36)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        chartRows
            .map { "\($0.label) \(Int($0.value.rounded()))" }
            .joined(separator: "，")
    }
}

// MARK: - Facts

struct TrustFactLabeledRows: View {
    let facts: TrustBehaviorFacts
    var includeBooking: Bool = false
    var responseHint: String? = nil

    var body: some View {
        LabeledContent {
            Text(
                facts.joinedTotal > 0
                    ? "\(facts.joinedKept)/\(facts.joinedTotal)"
                    : "暂无"
            )
        } label: {
            Label("参加履约", systemImage: "calendar.badge.checkmark")
                .platformContentSymbolStyle()
        }
        if let hostRate = hostRateText {
            LabeledContent("发起履约", value: hostRate)
        }
        if facts.accountAgeDays > 0 {
            LabeledContent("账号", value: "\(facts.accountAgeDays) 天")
        }
        if includeBooking {
            let bookingTotal = facts.bookingsCompleted + facts.bookingsCancelledOrRefunded
            if bookingTotal > 0 {
                LabeledContent("陪玩完成", value: "\(facts.bookingsCompleted)")
                LabeledContent("取消 / 退款", value: "\(facts.bookingsCancelledOrRefunded)")
            }
        }
        if let responseHint, !responseHint.isEmpty {
            LabeledContent("响应", value: responseHint)
        }
    }

    private var hostRateText: String? {
        let total = facts.hostedCompletedLike + facts.hostedCancelled
        guard total > 0 else { return nil }
        let rate = Int((Double(facts.hostedCompletedLike) / Double(total) * 100).rounded())
        return "\(rate)%"
    }
}

// MARK: - Badges

/// 形象认证 / 会员徽章条。
/// - `revealLocked == true`：未点亮也显示灰态（我的页 / 我的信誉）
/// - `revealLocked == false`：只展示已点亮（对外档案 / 搭子 / 好友 / 作者）
struct TrustCredentialBadgeStrip: View {
    var photoVerified: Bool
    var isMember: Bool
    var revealLocked: Bool = true

    private var showsPhoto: Bool { revealLocked || photoVerified }
    private var showsMember: Bool { revealLocked || isMember }

    var body: some View {
        if showsPhoto || showsMember {
            HStack(spacing: PlatformMetrics.minContentGap) {
                if showsPhoto {
                    credentialChip(
                        title: TrustBadgeKind.photoVerified.title,
                        systemImage: photoVerified
                            ? TrustBadgeKind.photoVerified.systemImage
                            : "checkmark.seal",
                        unlocked: photoVerified
                    )
                }
                if showsMember {
                    credentialChip(
                        title: TrustBadgeKind.activeMember.title,
                        systemImage: isMember
                            ? TrustBadgeKind.activeMember.systemImage
                            : "crown",
                        unlocked: isMember
                    )
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
        }
    }

    private var accessibilityLabel: String {
        var parts: [String] = []
        if showsPhoto {
            parts.append("认证\(photoVerified ? "已通过" : "未认证")")
        }
        if showsMember {
            parts.append("会员\(isMember ? "已开通" : "未开通")")
        }
        return parts.joined(separator: "，")
    }

    private func credentialChip(title: String, systemImage: String, unlocked: Bool) -> some View {
        // 与 `PlatformFilterChipButton` 一致：系统紧凑图文间距，避免 List 行内 Label 撑开 icon↔title。
        HStack(spacing: PlatformMetrics.detailMicroSpacing) {
            Image(systemName: systemImage)
                .symbolRenderingMode(unlocked ? .multicolor : .hierarchical)
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(unlocked ? .primary : .tertiary)
        .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
        .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
        .background(
            Capsule(style: .continuous)
                .fill(unlocked ? Color(.tertiarySystemFill) : Color(.quaternarySystemFill))
        )
        .fixedSize()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

/// 「我的信誉」里：形象认证 / 会员状态行（点亮前后都有）。
struct TrustCredentialStatusRows: View {
    var photoVerified: Bool
    var isMember: Bool

    var body: some View {
        LabeledContent {
            Text(photoVerified ? "已通过" : "未认证")
                .foregroundStyle(photoVerified ? PlatformStatus.success : .secondary)
        } label: {
            Label(
                TrustBadgeKind.photoVerified.title,
                systemImage: photoVerified
                    ? TrustBadgeKind.photoVerified.systemImage
                    : "person.crop.circle.badge.questionmark"
            )
            .symbolRenderingMode(photoVerified ? .multicolor : .hierarchical)
            .foregroundStyle(photoVerified ? .primary : .secondary)
        }

        LabeledContent {
            Text(isMember ? "已开通" : "未开通")
                .foregroundStyle(isMember ? PlatformStatus.success : .secondary)
        } label: {
            Label(
                TrustBadgeKind.activeMember.title,
                systemImage: isMember
                    ? TrustBadgeKind.activeMember.systemImage
                    : "checkmark.seal"
            )
            .symbolRenderingMode(isMember ? .multicolor : .hierarchical)
            .foregroundStyle(isMember ? .primary : .secondary)
        }
    }
}

struct TrustBadgeRow: View {
    let badges: [TrustBadge]
    var limit: Int = 8

    var body: some View {
        ForEach(Array(badges.prefix(limit))) { badge in
            Label(badge.title, systemImage: badge.systemImage)
                .platformContentSymbolStyle()
        }
    }
}

// MARK: - Tips

struct TrustTipList: View {
    let tips: [String]
    var systemImage: String = "arrow.up.right.circle"

    var body: some View {
        ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
            Label(tip, systemImage: systemImage)
                .platformContentSymbolStyle()
        }
    }
}
