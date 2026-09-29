//
//  LaunchTheme.swift
//  坐标系
//
//  启动 / 冷启动舞台底色（已登录模型加载、协议 Gate 等）。
//

import SwiftUI

enum LaunchSurface {
    /// 加载与冷启动共用舞台底色。
    static let stage = Color(.systemGroupedBackground)

    /// 启动舞台氛围网格（低饱和系统色）。
    static var stageMesh: MeshGradient {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                SIMD2(0.0, 0.0), SIMD2(0.5, 0.0), SIMD2(1.0, 0.0),
                SIMD2(0.0, 0.5), SIMD2(0.5, 0.5), SIMD2(1.0, 0.5),
                SIMD2(0.0, 1.0), SIMD2(0.5, 1.0), SIMD2(1.0, 1.0)
            ],
            colors: [
                Color(.systemGray6), Color(.systemBackground), Color(.systemGray5),
                Color(.secondarySystemBackground), Color(.systemGray6), Color(.systemBackground),
                Color(.systemGray5), Color(.secondarySystemGroupedBackground), Color(.systemGray6)
            ]
        )
    }
}

/// 启动舞台：Reduce Motion 时回退纯色，否则 MeshGradient。
struct LaunchStageBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                LaunchSurface.stage
            } else {
                LaunchSurface.stageMesh
            }
        }
        .ignoresSafeArea()
    }
}
