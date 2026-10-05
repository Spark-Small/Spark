//
//  PlatformFlowLayout.swift
//  坐标系
//
//  官方 `Layout` 协议的横向换行容器（WWDC22 Compose custom layouts）。
//  供喜好胶囊等「按内容 intrinsic 宽、自动折行」场景；勿用等宽 LazyVGrid 硬挤文案。
//

import SwiftUI

struct PlatformFlowLayout: Layout {
    var spacing: CGFloat = PlatformMetrics.inlineControlSpacing

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let result = arrange(subviews: subviews, maxWidth: maxWidth)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(subviews: subviews, maxWidth: bounds.width)
        for (index, frame) in result.frames.enumerated() {
            guard index < subviews.count else { break }
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []
        frames.reserveCapacity(subviews.count)

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widthUsed: CGFloat = 0

        let unlimited = !maxWidth.isFinite || maxWidth <= 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if !unlimited, x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widthUsed = max(widthUsed, x - spacing)
        }

        let height = y + rowHeight
        let width = unlimited ? widthUsed : min(maxWidth, widthUsed)
        return (CGSize(width: max(width, 0), height: max(height, 0)), frames)
    }
}
