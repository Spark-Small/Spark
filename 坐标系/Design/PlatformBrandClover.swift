//
//  PlatformBrandClover.swift
//  坐标系
//
//  品牌四叶草：App Icon 彩虹渐变矢量形态，供信封 / Wallet 票面复用。
//

import SwiftUI

enum PlatformBrandClover {
    /// 与 App Icon / 信封印章一致的 8 色（顺时针）。
    static let palette: [Color] = [
        Color(red: 0.93, green: 0.54, blue: 0.20),
        Color(red: 0.94, green: 0.76, blue: 0.26),
        Color(red: 0.50, green: 0.73, blue: 0.22),
        Color(red: 0.32, green: 0.64, blue: 0.44),
        Color(red: 0.34, green: 0.54, blue: 0.88),
        Color(red: 0.58, green: 0.47, blue: 0.85),
        Color(red: 0.88, green: 0.40, blue: 0.75),
        Color(red: 0.92, green: 0.38, blue: 0.39),
    ]

    /// 由种子稳定映射到 palette 中某一色（每片叶可独立取值）。
    static func paletteColor(seed: UInt64, leafIndex: Int) -> Color {
        var mixed = seed ^ (UInt64(leafIndex &* 2654435761))
        mixed = mixed &* 2862933555777941757 &+ 3037000493
        return palette[Int(mixed % UInt64(palette.count))]
    }

    /// 与 App Icon / 信封印章一致的 8 色顺时针渐变。
    static var rainbowFill: AngularGradient {
        AngularGradient(
            colors: palette + [palette[0]],
            center: .center
        )
    }
}

/// 单片心形叶（中心为茎点，指向上方）。
enum BrandCloverLeafUnit {
    static func path(length l: CGFloat) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addCurve(
            to: CGPoint(x: -0.48 * l, y: -0.58 * l),
            control1: CGPoint(x: -0.21 * l, y: -0.28 * l),
            control2: CGPoint(x: -0.44 * l, y: -0.40 * l)
        )
        path.addCurve(
            to: CGPoint(x: 0, y: -0.76 * l),
            control1: CGPoint(x: -0.50 * l, y: -0.84 * l),
            control2: CGPoint(x: -0.22 * l, y: -0.94 * l)
        )
        path.addCurve(
            to: CGPoint(x: 0.48 * l, y: -0.58 * l),
            control1: CGPoint(x: 0.22 * l, y: -0.94 * l),
            control2: CGPoint(x: 0.50 * l, y: -0.84 * l)
        )
        path.addCurve(
            to: .zero,
            control1: CGPoint(x: 0.44 * l, y: -0.40 * l),
            control2: CGPoint(x: 0.21 * l, y: -0.28 * l)
        )
        path.closeSubpath()
        return path
    }
}

/// 四片心形叶合成一条路径。
struct BrandCloverShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let length = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<4 {
            let transform = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: .pi / 2 * Double(index))
            path.addPath(BrandCloverLeafUnit.path(length: length), transform: transform)
        }
        return path
    }
}

/// 可着色的单片四叶草叶。
struct BrandCloverLeafShape: Shape {
    var length: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        return BrandCloverLeafUnit.path(length: length)
            .applying(CGAffineTransform(translationX: center.x, y: center.y))
    }
}

/// 四叶草随机着色：每片叶从 8 色 palette 中稳定取色。
struct BrandCloverRandomFill: View {
    var seed: UInt64

    var body: some View {
        GeometryReader { geo in
            let length = max(geo.size.width, geo.size.height) * 0.58
            ZStack {
                ForEach(0..<4, id: \.self) { index in
                    BrandCloverLeafShape(length: length)
                        .fill(PlatformBrandClover.paletteColor(seed: seed, leafIndex: index))
                        .rotationEffect(.degrees(Double(index) * 90))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Wallet / 信封用彩色四叶草 mark。
struct BrandCloverMark: View {
    var size: CGFloat = 36

    var body: some View {
        BrandCloverShape()
            .fill(PlatformBrandClover.rainbowFill)
            .frame(width: size, height: size)
            .accessibilityLabel("坐标系")
    }
}
