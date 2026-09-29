//
//  LocalPrivateDetectorProxy.swift
//  坐标系
//
//  演示用 Private Detector 代理：肤色占比 + 人脸覆盖启发式（非真实神经网络）。
//  正式环境由服务端 EfficientNet-v2 SavedModel 替换。
//

import CoreGraphics
import UIKit
import Vision

enum LocalPrivateDetectorProxy {
    struct Score: Sendable {
        var nsfwScore: Double
        var faceCoverage: Double
        var skinRatio: Double
    }

    /// 必须在后台线程调用；内部会先缩略再跑 Vision，避免真机大图卡死主线程。
    nonisolated static func score(imageData: Data) -> Score {
        guard let image = UIImage(data: imageData) else {
            return Score(nsfwScore: 0, faceCoverage: 0, skinRatio: 0)
        }
        return score(image: image)
    }

    /// 必须在后台线程调用；内部会先缩略再跑 Vision，避免真机大图卡死主线程。
    nonisolated static func score(image: UIImage) -> Score {
        // Vision / 像素扫描前先缩到 ≤512，真机 12MP 原图会卡数秒甚至看门狗
        guard let prepared = downscaledCGImage(from: image, maxSide: 512) else {
            return Score(nsfwScore: 0, faceCoverage: 0, skinRatio: 0)
        }
        let skin = skinRatio(in: prepared)
        let face = faceCoverage(in: prepared)
        var nsfw = skin
        if face >= 0.12 {
            nsfw *= max(0, 1 - face * 1.8)
        } else if face < 0.04 {
            nsfw = min(1, skin * 1.15)
        }
        return Score(nsfwScore: min(1, max(0, nsfw)), faceCoverage: face, skinRatio: skin)
    }

    private nonisolated static func downscaledCGImage(from image: UIImage, maxSide: CGFloat) -> CGImage? {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longest = max(pixelWidth, pixelHeight)
        guard longest > 0 else { return image.cgImage }

        let scale = min(1, maxSide / longest)
        let target = CGSize(
            width: max(1, (pixelWidth * scale).rounded(.down)),
            height: max(1, (pixelHeight * scale).rounded(.down))
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return rendered.cgImage
    }

    private nonisolated static func faceCoverage(in cgImage: CGImage) -> Double {
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return 0
        }
        let faces = request.results ?? []
        guard let largest = faces.max(by: {
            ($0.boundingBox.width * $0.boundingBox.height) < ($1.boundingBox.width * $1.boundingBox.height)
        }) else { return 0 }
        return Double(largest.boundingBox.width * largest.boundingBox.height)
    }

    private nonisolated static func skinRatio(in cgImage: CGImage) -> Double {
        let width = min(cgImage.width, 64)
        let height = min(cgImage.height, 64)
        guard width > 0, height > 0 else { return 0 }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0 }

        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var skin = 0
        let total = width * height
        for i in 0..<total {
            let o = i * 4
            let r = Double(pixels[o])
            let g = Double(pixels[o + 1])
            let b = Double(pixels[o + 2])
            if isSkinTone(r: r, g: g, b: b) { skin += 1 }
        }
        return Double(skin) / Double(max(total, 1))
    }

    private nonisolated static func isSkinTone(r: Double, g: Double, b: Double) -> Bool {
        let y = 0.299 * r + 0.587 * g + 0.114 * b
        let cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b
        let cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b
        return y > 40 && y < 240 && cb > 77 && cb < 127 && cr > 133 && cr < 173
    }
}
