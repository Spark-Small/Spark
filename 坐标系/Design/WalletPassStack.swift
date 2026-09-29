//
//  WalletPassStack.swift
//  坐标系
//
//  对齐系统 Wallet 叠卡：首张在前完整可见；后方只露 header 条；多卡压缩露条。
//

import SwiftUI

/// 长条凭证堆样式。
enum WalletPassStackStyle: Hashable {
    /// 「我的」预览：系统 header 露条。
    case collapsed
    /// 凭证夹：露条略大。
    case scrolling

    var peek: CGFloat {
        switch self {
        case .collapsed: PlatformMetrics.walletPassStackCollapsedPeek
        case .scrolling: PlatformMetrics.walletPassStackScrollingPeek
        }
    }

    var maxExtraHeight: CGFloat { PlatformMetrics.walletPassStackMaxExtraHeight }
}

/// 长条凭证纵向叠放（系统 Wallet 同构）。
///
/// - 数组首项 = 最前完整凭证（贴堆底）
/// - 后方凭证向上错位，只露出约 header 高的条带
/// - 张数多时压缩 peek，总增高不超过 `maxExtraHeight`
struct WalletPassStack<Item: Identifiable, Content: View>: View {
    let items: [Item]
    var style: WalletPassStackStyle = .collapsed
    @ViewBuilder var content: (Item) -> Content

    @Environment(\.platformChromeMeasurements) private var chromeMeasurements

    var body: some View {
        if items.isEmpty {
            EmptyView()
        } else {
            WalletPassStackLayout(
                peek: style.peek,
                fallbackBarHeight: PlatformMetrics.walletPassStripBarHeight(
                    navigationBarButtonSide: chromeMeasurements.navigationBarButtonSide
                ),
                maxExtraHeight: style.maxExtraHeight
            ) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    content(item)
                        .compositingGroup()
                        .zIndex(Double(items.count - 1 - index))
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
        }
    }
}

/// 堆布局：首张贴底；总高 = 条高 + min((n−1)×peek, maxExtra)。
private struct WalletPassStackLayout: Layout {
    var peek: CGFloat
    var fallbackBarHeight: CGFloat
    var maxExtraHeight: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let width = proposal.width
            ?? subviews.map { $0.sizeThatFits(.unspecified).width }.max()
            ?? 0
        let barHeight = measuredBarHeight(width: width, subviews: subviews)
        let step = effectivePeek(count: subviews.count)
        let height = barHeight + CGFloat(max(subviews.count - 1, 0)) * step
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let width = bounds.width
        let barHeight = measuredBarHeight(width: width, subviews: subviews)
        let step = effectivePeek(count: subviews.count)
        let count = subviews.count
        let cardProposal = ProposedViewSize(width: width, height: barHeight)

        for (index, subview) in subviews.enumerated() {
            // index 0（首张/最前）贴堆底；后方卡在其上方露出 header
            let y = bounds.minY + CGFloat(count - 1 - index) * step
            subview.place(
                at: CGPoint(x: bounds.minX, y: y),
                anchor: .topLeading,
                proposal: cardProposal
            )
        }
    }

    private func measuredBarHeight(width: CGFloat, subviews: Subviews) -> CGFloat {
        guard let first = subviews.first else { return fallbackBarHeight }
        let measured = first.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        return max(measured, fallbackBarHeight)
    }

    /// 多卡时压缩露条，贴近系统 Wallet 堆高度上限行为。
    private func effectivePeek(count: Int) -> CGFloat {
        let gaps = max(count - 1, 0)
        guard gaps > 0 else { return peek }
        let uncapped = peek * CGFloat(gaps)
        if uncapped <= maxExtraHeight { return peek }
        return maxExtraHeight / CGFloat(gaps)
    }
}

#Preview("Wallet pass strip stack") {
    ScrollView {
        WalletPassStack(
            items: Array(SampleData.activities.prefix(4)),
            style: .collapsed
        ) { activity in
            ProfileActivityCredentialStrip(activity: activity, titleOnly: true)
        }
        .padding(.horizontal, PlatformMetrics.contentInset)
    }
    .platformChromeMeasurementsEnvironment()
}
