// Module: SparkNetworking — Memory-efficient image decode via ImageIO.

import ImageIO
import UIKit

enum RemoteImageError: Error {
    case invalidData
}

extension UIImage {
    /// Decodes and downscales image data off the full-resolution decode path.
    static func downsampled(from data: Data, maxPixelSize: CGFloat) throws -> UIImage {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else {
            throw RemoteImageError.invalidData
        }
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions as CFDictionary
        ) else {
            throw RemoteImageError.invalidData
        }
        return UIImage(cgImage: cgImage)
    }
}
