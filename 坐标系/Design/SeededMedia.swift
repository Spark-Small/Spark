//
//  SeededMedia.swift
//  坐标系
//
//  离线种子图：确定性渐变 + SF Symbol 场景。
//

import SwiftUI

enum SeededPalette {
    /// 系统语义色轮转，避免自定义品牌色
    static let fills: [Color] = [
        .blue, .teal, .indigo, .cyan, .mint,
        .orange, .pink, .purple, .green, .brown
    ]

    static func primary(for seed: Int) -> Color {
        fills[abs(seed) % fills.count]
    }

    static func secondary(for seed: Int) -> Color {
        fills[abs(seed / 7) % fills.count]
    }
}

/// 封面 / 相册用的本地场景图
struct SeededSceneFill: View {
    let seed: Int
    var symbol: String = "photo"
    var showsSymbol = true

    var body: some View {
        let primary = SeededPalette.primary(for: seed)
        let secondary = SeededPalette.secondary(for: seed)
        let tilt = Double(abs(seed % 40)) / 100
        let layout = abs(seed) % 3
        let symbolSize: CGFloat = layout == 0 ? 54 : (layout == 1 ? 44 : 62)
        let symbolAnchor = layout == 1
            ? Alignment.bottomTrailing
            : (layout == 2 ? Alignment.topLeading : Alignment.center)

        ZStack {
            LinearGradient(
                colors: layout == 2
                    ? [secondary.opacity(0.4), primary.opacity(0.5), Color(.tertiarySystemFill)]
                    : [
                        primary.opacity(0.55),
                        secondary.opacity(0.35),
                        Color(.secondarySystemFill)
                    ],
                startPoint: UnitPoint(x: 0.1 + tilt, y: layout == 1 ? 1 : 0),
                endPoint: UnitPoint(x: 0.9 - tilt, y: layout == 1 ? 0 : 1)
            )

            GeometryReader { geo in
                Circle()
                    .fill(primary.opacity(layout == 0 ? 0.22 : 0.16))
                    .frame(width: geo.size.width * (layout == 2 ? 0.9 : 0.72))
                    .offset(
                        x: geo.size.width * (layout == 1 ? -0.2 : (0.35 + tilt)),
                        y: -geo.size.height * (layout == 2 ? 0.08 : 0.18)
                    )
                Circle()
                    .fill(secondary.opacity(0.18))
                    .frame(width: geo.size.width * (layout == 1 ? 0.7 : 0.55))
                    .offset(
                        x: -geo.size.width * (layout == 2 ? 0.05 : 0.22),
                        y: geo.size.height * (layout == 1 ? 0.28 : 0.42)
                    )
                if layout != 1 {
                    RoundedRectangle(cornerRadius: PlatformMetrics.radiusEditorial, style: .continuous)
                        .fill(.white.opacity(0.08))
                        .frame(width: geo.size.width * 0.42, height: geo.size.height * 0.28)
                        .rotationEffect(.degrees(Double(seed % 18) - 9))
                        .offset(x: geo.size.width * 0.12, y: geo.size.height * 0.2)
                }
            }

            if showsSymbol {
                Image(systemName: symbol)
                    .font(.system(size: symbolSize, weight: .semibold))
                    .platformSymbolStyle(.hierarchical)
                    .foregroundStyle(.primary.opacity(0.85))
                    .colorScheme(.dark)
                    .padding(layout == 0 ? 0 : 28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: symbolAnchor)
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// 姓名确定性头像底色
struct SeededAvatarView: View {
    let name: String
    var size: CGFloat = 32

    private var seed: Int { abs(name.hashValue) }
    private var initial: String { String(name.prefix(1)) }
    private var tint: Color { SeededPalette.primary(for: seed) }

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [tint.opacity(0.35), tint.opacity(0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Circle().strokeBorder(tint.opacity(0.28), lineWidth: 0.5)
            }
            .overlay {
                Text(initial)
                    .font(.system(size: max(11, size * 0.42), weight: .semibold, design: .rounded))
                    .foregroundStyle(tint)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// 搭子人像占位：全幅铺满圆框（隔空投送式），渐变底 + 大号面容
struct SeededPersonFill: View {
    let seed: Int
    let name: String

    private var tint: Color { SeededPalette.primary(for: seed) }
    private var secondary: Color { SeededPalette.secondary(for: seed) }
    private var initial: String { String(name.prefix(1)) }
    private var tilt: Double { Double(abs(seed % 36)) / 100 }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let face = side * 0.72

            ZStack {
                LinearGradient(
                    colors: [
                        tint.opacity(0.55),
                        secondary.opacity(0.32),
                        Color(.secondarySystemFill)
                    ],
                    startPoint: UnitPoint(x: 0.15 + tilt, y: 0),
                    endPoint: UnitPoint(x: 0.85 - tilt, y: 1)
                )

                Circle()
                    .fill(tint.opacity(0.22))
                    .frame(width: side * 0.95)
                    .offset(y: -side * 0.22)

                Circle()
                    .fill(secondary.opacity(0.18))
                    .frame(width: side * 0.78)
                    .offset(
                        x: side * (0.22 - tilt),
                        y: side * 0.32
                    )

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.45),
                                    tint.opacity(0.62)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text(initial)
                        .font(.system(size: face * 0.42, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .colorScheme(.dark)
                }
                .frame(width: face, height: face)
                .offset(y: side * 0.06)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

/// 作者目录：社区 / 活动发起人兜底资料
struct AuthorDirectoryProfile: Identifiable, Hashable {
    var id: String { name }
    var name: String
    var city: String
    var bio: String
    var tags: [String]
    var hostedCount: Int
    var joinedCount: Int
    var roleLabel: String
}
