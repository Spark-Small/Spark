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

/// 防欺诈认证 / 会员徽章条（本地胶囊徽章，非系统 glass CTA）。
/// - `revealLocked == true`：未点亮也显示灰态（我的页 / 我的信誉）
/// - `revealLocked == false`：只展示已点亮（对外档案 / 搭子 / 好友 / 作者）
/// - `usesActionTitles == true`：分态行动文案（开始认证 / 已认证 · 开通会员 / 会员中心）
struct TrustCredentialBadgeStrip: View {
    var photoVerified: Bool
    var isMember: Bool
    var revealLocked: Bool = true
    var usesActionTitles: Bool = false
    var onPhotoTap: (() -> Void)? = nil
    var onMemberTap: (() -> Void)? = nil
    var photoAccessibilityHint: String? = nil
    var memberAccessibilityHint: String? = nil

    private var showsPhoto: Bool { revealLocked || photoVerified }
    private var showsMember: Bool { revealLocked || isMember }
    private var usesInteractiveChips: Bool { onPhotoTap != nil || onMemberTap != nil }

    var body: some View {
        if showsPhoto || showsMember {
            let strip = HStack(spacing: PlatformMetrics.minContentGap) {
                if showsPhoto {
                    credentialChip(
                        title: photoTitle,
                        systemImage: photoVerified
                            ? TrustBadgeKind.photoVerified.systemImage
                            : "checkmark.seal",
                        unlocked: photoVerified,
                        hint: photoAccessibilityHint,
                        action: onPhotoTap
                    )
                }
                if showsMember {
                    credentialChip(
                        title: memberTitle,
                        systemImage: isMember
                            ? TrustBadgeKind.activeMember.systemImage
                            : "crown",
                        unlocked: isMember,
                        hint: memberAccessibilityHint,
                        action: onMemberTap
                    )
                }
            }

            if usesInteractiveChips {
                strip.accessibilityElement(children: .contain)
            } else {
                strip
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(combinedAccessibilityLabel)
            }
        }
    }

    private var photoTitle: String {
        if usesActionTitles {
            return photoVerified ? "已认证" : "开始认证"
        }
        return TrustBadgeKind.photoVerified.title
    }

    private var memberTitle: String {
        if usesActionTitles {
            return isMember ? "会员中心" : "开通会员"
        }
        return TrustBadgeKind.activeMember.title
    }

    private var combinedAccessibilityLabel: String {
        var parts: [String] = []
        if showsPhoto {
            parts.append("认证\(photoVerified ? "已通过" : "未认证")")
        }
        if showsMember {
            parts.append("会员\(isMember ? "已开通" : "未开通")")
        }
        return parts.joined(separator: "，")
    }

    @ViewBuilder
    private func credentialChip(
        title: String,
        systemImage: String,
        unlocked: Bool,
        hint: String?,
        action: (() -> Void)?
    ) -> some View {
        let chip = HStack(spacing: PlatformMetrics.detailMicroSpacing) {
            Image(systemName: systemImage)
                .symbolRenderingMode(unlocked ? .multicolor : .hierarchical)
                .imageScale(.small)
            Text(title)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(unlocked ? .primary : .tertiary)
        .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
        .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
        .background(
            Capsule(style: .continuous)
                .fill(unlocked ? Color(.tertiarySystemFill) : Color(.quaternarySystemFill))
        )
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(
                    unlocked ? Color.accentColor.opacity(0.28) : Color.clear,
                    lineWidth: 0.5
                )
        }
        .fixedSize()
        .contentShape(Capsule(style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(action == nil ? [] : .isButton)
        .accessibilityHint(hint ?? "")

        if let action {
            Button(action: action) { chip }
                .buttonStyle(.plain)
        } else {
            chip
        }
    }
}

/// 「我的信誉」里：防欺诈认证 / 会员状态行（点亮前后都有）。
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
        // 兼容旧调用：改为奖章墙（仅已点亮）
        TrustBadgeShowcase(
            earned: Array(badges.prefix(limit)),
            mode: .publicEarned
        )
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
