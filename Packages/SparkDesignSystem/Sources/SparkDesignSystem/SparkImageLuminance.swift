// Module: SparkDesignSystem — Sample photo brightness for overlay text contrast.

import UIKit

public enum SparkImageLuminance {
    /// Whether the bottom band of an image reads as light (prefer dark foreground text).
    ///
    /// - Parameters:
    ///   - image: Cover image in display orientation.
    ///   - bottomBandFraction: Portion of height sampled from the bottom edge (overlay region).
    ///   - lightThreshold: Relative luminance above which the band is treated as light.
    public static func isLightBackground(
        in image: UIImage,
        bottomBandFraction: CGFloat = 0.35,
        lightThreshold: CGFloat = 0.55
    ) -> Bool {
        let sampleSize = CGSize(width: 32, height: 32)
        let renderer = UIGraphicsImageRenderer(size: sampleSize)
        let sampled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: sampleSize))
        }
        guard let cgImage = sampled.cgImage else { return false }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return false }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return false }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let clampedFraction = min(max(bottomBandFraction, 0.1), 1)
        let bottomRowStart = Int((1 - clampedFraction) * CGFloat(height))
        var totalLuminance = 0.0
        var count = 0

        for y in bottomRowStart ..< height {
            for x in 0 ..< width {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let red = Double(pixels[offset]) / 255
                let green = Double(pixels[offset + 1]) / 255
                let blue = Double(pixels[offset + 2]) / 255
                totalLuminance += 0.2126 * red + 0.7152 * green + 0.0722 * blue
                count += 1
            }
        }

        guard count > 0 else { return false }
        return (totalLuminance / Double(count)) > Double(lightThreshold)
    }
}
