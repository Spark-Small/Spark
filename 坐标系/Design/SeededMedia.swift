//
//  SeededMedia.swift
//  坐标系
//
//  离线种子图：确定性渐变 + SF Symbol；滚动路径不用 GeometryReader。
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

/// 封面 / 相册用的本地场景图（轻量：渐变 + Symbol，适合 LazyVStack / LazyHStack）
struct SeededSceneFill: View {
    let seed: Int
    var symbol: String = "photo"
    var showsSymbol = true

    var body: some View {
        let primary = SeededPalette.primary(for: seed)
        let secondary = SeededPalette.secondary(for: seed)
        let tilt = Double(abs(seed % 40)) / 100
        let layout = abs(seed) % 3
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

            if showsSymbol {
                Image(systemName: symbol)
                    .font(.system(.largeTitle, design: .default))
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

/// 搭子人像占位：全幅铺满；固定比例装饰，滚动路径不用 GeometryReader
struct SeededPersonFill: View {
    let seed: Int
    let name: String

    private var tint: Color { SeededPalette.primary(for: seed) }
    private var secondary: Color { SeededPalette.secondary(for: seed) }
    private var initial: String { String(name.prefix(1)) }
    private var tilt: Double { Double(abs(seed % 36)) / 100 }

    var body: some View {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(0.95)
                .offset(y: -24)

            Circle()
                .fill(secondary.opacity(0.18))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(0.78)
                .offset(x: 20 - tilt * 40, y: 28)

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
                    .font(.system(.largeTitle, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.primary)
                    .colorScheme(.dark)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(18)
            .offset(y: 8)
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
