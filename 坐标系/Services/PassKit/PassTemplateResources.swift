//
//  PassTemplateResources.swift
//  坐标系
//
//  Apple Wallet 官方模板尺寸与资源渲染（Pass Design and Creation）。
//  参考：icon 29pt · logo 160×50pt · event strip 375×98pt · @2x/@3x。
//

import CoreGraphics
import SwiftUI
import UIKit
import CoordinateModels

enum PassTemplateResources {
    enum AssetKind {
        case icon
        case logo
        case eventStrip

        /// 1x 点尺寸（宽 × 高）
        var baseSize: CGSize {
            switch self {
            case .icon: CGSize(width: 29, height: 29)
            case .logo: CGSize(width: 160, height: 50)
            case .eventStrip: CGSize(width: 375, height: 98)
            }
        }

        var fileStem: String {
            switch self {
            case .icon: "icon"
            case .logo: "logo"
            case .eventStrip: "strip"
            }
        }
    }

    enum ImageScale: CaseIterable {
        case x1
        case x2
        case x3

        var multiplier: CGFloat {
            switch self {
            case .x1: 1
            case .x2: 2
            case .x3: 3
            }
        }

        var suffix: String {
            switch self {
            case .x1: ""
            case .x2: "@2x"
            case .x3: "@3x"
            }
        }
    }

    static func fileName(kind: AssetKind, scale: ImageScale) -> String {
        "\(kind.fileStem)\(scale.suffix).png"
    }

    static func pixelSize(kind: AssetKind, scale: ImageScale) -> CGSize {
        let base = kind.baseSize
        let m = scale.multiplier
        return CGSize(width: base.width * m, height: base.height * m)
    }

    static func rgbString(red: Int, green: Int, blue: Int) -> String {
        "rgb(\(red), \(green), \(blue))"
    }

    static func rgbString(from color: UIColor) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return rgbString(
            red: Int((r * 255).rounded()),
            green: Int((g * 255).rounded()),
            blue: Int((b * 255).rounded())
        )
    }

    /// 活动分类 → pass.json backgroundColor + strip 画布色（与 App 内票面一致）。
    static func activityAppearance(for category: ActivityCategory) -> (backgroundRGB: String, stripUIColor: UIColor) {
        (
            WalletPassEventTicketAppearance.backgroundRGB(for: category),
            WalletPassEventTicketAppearance.uiStripSurfaceColor(for: category)
        )
    }

    static func uiStripSurfaceColor(for appearanceKey: String?) -> UIColor {
        let category = ActivityCategory(rawValue: appearanceKey ?? "") ?? .forYou
        return WalletPassEventTicketAppearance.uiStripSurfaceColor(for: category)
    }

    static func uiBackgroundColor(for category: ActivityCategory) -> UIColor {
        WalletPassEventTicketAppearance.uiBackgroundColor(for: category)
    }

    // MARK: - Render

    static func iconPNG(systemName: String) -> [String: Data] {
        renderScaled(kind: .icon) { size in
            drawSymbol(systemName: systemName, in: size, onDark: true)
        }
    }

    static func logoPNG(systemName: String = "wallet.bifold.fill") -> [String: Data] {
        renderScaled(kind: .logo) { size in
            drawSymbol(systemName: systemName, in: size, onDark: false, fillBackground: false)
        }
    }

    static func eventStripPNG(
        stripColor: UIColor,
        cover: UIImage? = nil,
        usesCredentialArt: Bool = false
    ) -> [String: Data] {
        renderScaled(kind: .eventStrip) { size in
            drawEventStrip(
                size: size,
                baseColor: stripColor,
                cover: cover,
                usesCredentialArt: usesCredentialArt
            )
        }
    }

    private static func renderScaled(
        kind: AssetKind,
        draw: (CGSize) -> UIImage?
    ) -> [String: Data] {
        var files: [String: Data] = [:]
        for scale in ImageScale.allCases {
            let size = pixelSize(kind: kind, scale: scale)
            guard let image = draw(size), let data = image.pngData() else { continue }
            files[fileName(kind: kind, scale: scale)] = data
        }
        return files
    }

    private static func drawSymbol(
        systemName: String,
        in size: CGSize,
        onDark: Bool,
        fillBackground: Bool = true
    ) -> UIImage? {
        let side = min(size.width, size.height)
        let config = UIImage.SymbolConfiguration(pointSize: side * 0.52, weight: .semibold)
        guard let symbol = UIImage(systemName: systemName, withConfiguration: config) else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = fillBackground
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            if fillBackground {
                UIColor.black.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }
            let tint: UIColor = onDark ? .white : UIColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
            let rendered = symbol.withTintColor(tint, renderingMode: .alwaysOriginal)
            let symbolSize = rendered.size
            let origin = CGPoint(
                x: (size.width - symbolSize.width) / 2,
                y: (size.height - symbolSize.height) / 2
            )
            rendered.draw(in: CGRect(origin: origin, size: symbolSize))
        }
    }

    private static func drawEventStrip(
        size: CGSize,
        baseColor: UIColor,
        cover: UIImage?,
        usesCredentialArt: Bool
    ) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            if let cover {
                cover.draw(in: rect)
                let overlayAlpha: CGFloat = usesCredentialArt ? 0.14 : 0.45
                UIColor.black.withAlphaComponent(overlayAlpha).setFill()
                ctx.fill(rect)
            } else {
                baseColor.setFill()
                ctx.fill(rect)
                var hue: CGFloat = 0
                var saturation: CGFloat = 0
                var brightness: CGFloat = 0
                var alpha: CGFloat = 0
                if baseColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha),
                   brightness > 0.72 {
                    UIColor.white.withAlphaComponent(0.35).setFill()
                    ctx.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.42))
                } else {
                    let top = baseColor.withAlphaComponent(0.92)
                    let bottom = baseColor.withAlphaComponent(0.78)
                    if let gradient = CGGradient(
                        colorsSpace: CGColorSpaceCreateDeviceRGB(),
                        colors: [top.cgColor, bottom.cgColor] as CFArray,
                        locations: [0, 1]
                    ) {
                        ctx.cgContext.drawLinearGradient(
                            gradient,
                            start: CGPoint(x: 0, y: 0),
                            end: CGPoint(x: size.width, y: size.height),
                            options: []
                        )
                    }
                    UIColor.white.withAlphaComponent(0.06).setFill()
                    ctx.fill(rect)
                }
            }
        }
    }
}
