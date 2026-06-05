// Module: SparkLikes — Photos-style pinch / double-tap zoom state.

import SwiftUI
import UIKit

@MainActor
@Observable
final class DiscoverPhotoZoomState {
    var scale: CGFloat = 1
    var offset: CGSize = .zero

    private let minScale: CGFloat = 1
    private let doubleTapScale: CGFloat = 2
    private let maxScale: CGFloat = 4

    var isZoomed: Bool {
        scale > minScale + 0.01
            || abs(offset.width) > 0.5
            || abs(offset.height) > 0.5
    }

    func reset(animated: Bool = true) {
        apply(scale: minScale, offset: .zero, animated: animated)
    }

    func toggleDoubleTap(fitSize: CGSize, container: CGSize) {
        if isZoomed {
            reset(animated: true)
        } else {
            let target = min(doubleTapScale, maxScale)
            apply(scale: target, offset: .zero, animated: true)
            offset = boundedOffset(
                proposed: offset,
                fitSize: fitSize,
                container: container,
                scale: target
            )
        }
    }

    func applyMagnification(
        baseScale: CGFloat,
        magnification: CGFloat,
        fitSize: CGSize,
        container: CGSize
    ) {
        let proposed = min(max(baseScale * magnification, minScale), maxScale)
        scale = proposed
        offset = boundedOffset(proposed: offset, fitSize: fitSize, container: container, scale: proposed)
    }

    func applyDrag(translation: CGSize, fitSize: CGSize, container: CGSize) {
        guard isZoomed else { return }
        offset = boundedOffset(
            proposed: CGSize(
                width: offset.width + translation.width,
                height: offset.height + translation.height
            ),
            fitSize: fitSize,
            container: container,
            scale: scale
        )
    }

    func boundedOffset(
        proposed: CGSize,
        fitSize: CGSize,
        container: CGSize,
        scale: CGFloat
    ) -> CGSize {
        let scaledWidth = fitSize.width * scale
        let scaledHeight = fitSize.height * scale
        let maxX = max(0, (scaledWidth - container.width) / 2)
        let maxY = max(0, (scaledHeight - container.height) / 2)
        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }

    private func apply(scale: CGFloat, offset: CGSize, animated: Bool) {
        let shouldAnimate = animated && !UIAccessibility.isReduceMotionEnabled
        if shouldAnimate {
            withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                self.scale = scale
                self.offset = offset
            }
        } else {
            self.scale = scale
            self.offset = offset
        }
    }
}

/// Reports when the visible card photo is pinch-zoomed (disables feed paging).
struct DiscoverPhotoZoomedPreferenceKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
