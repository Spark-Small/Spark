//
//  TrustBadgeShowcase.swift
//  坐标系
//
//  信任奖章墙：对齐 Game Center / Fitness Awards——图标为主、短标题为辅。
//  对外：只展示已点亮；对内集合：未点亮灰态占位，不讲空话。
//

import SwiftUI

/// 奖章墙展示策略。
enum TrustBadgeShowcaseMode: Equatable {
    /// 好友 / 作者 / 搭子 / 信任档案预览：仅已点亮
    case publicEarned
    /// 「我的信誉」：公开种类全量，未点亮灰态
    case privateCollection
}

/// 单枚奖章（SF Symbol + 短标题；禁止装饰色块章）。
struct TrustBadgeMedalView: View {
    let kind: TrustBadgeKind
    var unlocked: Bool

    var body: some View {
        VStack(spacing: PlatformMetrics.detailMicroSpacing) {
            Image(systemName: kind.systemImage)
                .font(.title2)
                .symbolRenderingMode(unlocked ? .multicolor : .hierarchical)
                .foregroundStyle(unlocked ? .primary : .tertiary)
                .frame(width: 36, height: 36)

            Text(kind.showcaseTitle)
                .font(.caption2.weight(.medium))
                .foregroundStyle(unlocked ? .secondary : .tertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(kind.showcaseTitle)，\(unlocked ? "已点亮" : "未点亮")")
    }
}

/// 信任档案 / 我的信誉共用的奖章格。
struct TrustBadgeShowcase: View {
    let earned: [TrustBadge]
    var mode: TrustBadgeShowcaseMode = .publicEarned

    private var earnedKinds: Set<TrustBadgeKind> {
        Set(earned.map(\.kind))
    }

    private var slots: [(kind: TrustBadgeKind, unlocked: Bool)] {
        switch mode {
        case .publicEarned:
            return TrustBadgeKind.publicArchiveCases.compactMap { kind in
                guard earnedKinds.contains(kind) else { return nil }
                return (kind, true)
            }
        case .privateCollection:
            return TrustBadgeKind.publicArchiveCases.map { kind in
                (kind, earnedKinds.contains(kind))
            }
        }
    }

    var body: some View {
        if !slots.isEmpty {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 72), spacing: PlatformMetrics.minContentGap)
                ],
                spacing: PlatformMetrics.cardInfoSpacing
            ) {
                ForEach(slots, id: \.kind) { slot in
                    TrustBadgeMedalView(kind: slot.kind, unlocked: slot.unlocked)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(accessibilitySummary)
        }
    }

    private var accessibilitySummary: String {
        let lit = slots.filter(\.unlocked).map(\.kind.showcaseTitle)
        if lit.isEmpty { return "暂无已点亮认证徽章" }
        return "已点亮：\(lit.joined(separator: "、"))"
    }
}
