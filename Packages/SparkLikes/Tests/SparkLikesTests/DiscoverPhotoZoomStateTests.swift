// Module: SparkLikesTests — Photo zoom state.

@testable import SparkLikes
import CoreGraphics
import Testing

@MainActor
struct DiscoverPhotoZoomStateTests {
    @Test func doubleTapTogglesZoom() {
        let state = DiscoverPhotoZoomState()
        let fit = CGSize(width: 200, height: 300)
        let container = CGSize(width: 390, height: 844)

        state.toggleDoubleTap(fitSize: fit, container: container)
        #expect(state.isZoomed)

        state.toggleDoubleTap(fitSize: fit, container: container)
        #expect(!state.isZoomed)
    }

    @Test func resetClearsOffsetAndScale() {
        let state = DiscoverPhotoZoomState()
        let fit = CGSize(width: 200, height: 300)
        let container = CGSize(width: 390, height: 844)
        state.toggleDoubleTap(fitSize: fit, container: container)
        state.reset(animated: false)
        #expect(state.scale == 1)
        #expect(state.offset == .zero)
    }

    @Test func boundedOffsetClampsPan() {
        let state = DiscoverPhotoZoomState()
        let fit = CGSize(width: 200, height: 300)
        let container = CGSize(width: 390, height: 844)
        state.applyMagnification(
            baseScale: 1,
            magnification: 2,
            fitSize: fit,
            container: container
        )
        state.applyDrag(
            translation: CGSize(width: 10_000, height: 10_000),
            fitSize: fit,
            container: container
        )
        let maxX = max(0, (fit.width * state.scale - container.width) / 2)
        #expect(abs(state.offset.width) <= maxX + 0.01)
    }
}
