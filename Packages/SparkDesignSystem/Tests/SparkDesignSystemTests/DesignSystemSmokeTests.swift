// Module: SparkDesignSystemTests

import SparkDesignSystem
import Testing
import UIKit

@Suite(.serialized)
@MainActor
struct DesignSystemSmokeTests {
    @Test func placeholderCardBuilds() {
        _ = SparkPlaceholderCard(title: "A", subtitle: "B", systemImage: "star")
    }

    @Test func layoutMetricsMatchTabScreensSpec() {
        #expect(SparkLayoutMetrics.standardHorizontalPadding == 16)
        #expect(SparkLayoutMetrics.minimumTouchTarget == 44)
        #expect(SparkLayoutMetrics.sparkCardCornerRadius == 20)
        #expect(SparkLayoutMetrics.inboxModuleInnerPadding == 14)
        #expect(SparkLayoutMetrics.actionCardInnerPadding == SparkLayoutMetrics.inboxModuleInnerPadding)
        #expect(SparkLayoutMetrics.matchCardMaxWidth == 420)
    }

    @Test func imageLuminanceDetectsLightAndDarkBottomBands() {
        let darkImage = UIImage(color: .black, size: CGSize(width: 40, height: 40))
        let lightImage = UIImage(color: .white, size: CGSize(width: 40, height: 40))

        #expect(SparkImageLuminance.isLightBackground(in: darkImage) == false)
        #expect(SparkImageLuminance.isLightBackground(in: lightImage) == true)
    }

    @Test func photoOverlayContrastPairsScrimAndForeground() {
        let darkImage = UIImage(color: .black, size: CGSize(width: 40, height: 40))
        let lightImage = UIImage(color: .white, size: CGSize(width: 40, height: 40))

        let darkContrast = SparkPhotoOverlayContrast.analyze(image: darkImage)
        #expect(darkContrast.resolution == .darkBackground)
        #expect(darkContrast.scrimStyle == .darkBackground)
        #expect(darkContrast.foregroundColor(for: .primary) == .white)

        let lightContrast = SparkPhotoOverlayContrast.analyze(image: lightImage)
        #expect(lightContrast.resolution == .lightBackground)
        #expect(lightContrast.scrimStyle == .lightBackground)
        #expect(lightContrast.foregroundColor(for: .primary) == .black)

        #expect(SparkPhotoOverlayContrast.unknown.scrimStyle == .unknown)
        #expect(SparkPhotoOverlayContrast.unknown.foregroundColor(for: .primary) == .primary)
    }
}

private extension UIImage {
    convenience init(color: UIColor, size: CGSize) {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        guard let cgImage = image.cgImage else {
            self.init()
            return
        }
        self.init(cgImage: cgImage)
    }
}
