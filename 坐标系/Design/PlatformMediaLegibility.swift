//
//  PlatformMediaLegibility.swift
//  坐标系
//
//  封面 Material 底栏完整样式方案（对齐 App Store Today / 系统 Material 分档）：
//  按卡片角色选 style → 统一 inset + Material + 降透回退；文案/CTA 仍用系统语义色与 glass。
//  搭子人像发现卡：图下文案，不走本 helper。
//

import SwiftUI

// MARK: - Style（按卡片角色，勿在 Features 手写 Material）

/// 封面信息栏样式：角色 → 系统 Material 厚度。
/// 越「英雄 / 大图」越透、跟色越强；越「小海报」越实、越偏 chrome。
enum PlatformMediaInfoBarStyle: Equatable, Sendable {
    /// 精选 Hero、焦点 Editorial：`.ultraThinMaterial`
    case hero
    /// 发现流大卡、跟进 / 热场 / 赛事横卡：`.thinMaterial`
    case standard
    /// 榜单竖海报等小卡：`.bar`（工具栏档，更偏中性 chrome）
    case compact

    var material: Material {
        switch self {
        case .hero: .ultraThinMaterial
        case .standard: .thinMaterial
        case .compact: .bar
        }
    }

    /// 卡内底栏内容边距（与页边同源 `mediaChromeInset`）。
    var contentInset: CGFloat {
        PlatformMetrics.mediaChromeInset
    }
}

// MARK: - Chrome

extension View {
    /// 封面底栏完整构建：内容 inset → 铺满底边 → 角色 Material（降透用不透明系统底）。
    /// - Parameter style: 卡片角色；默认 `.standard`。
    func platformMediaInfoBarChrome(
        _ style: PlatformMediaInfoBarStyle = .standard
    ) -> some View {
        modifier(PlatformMediaInfoBarChromeModifier(style: style))
    }
}

private struct PlatformMediaInfoBarChromeModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let style: PlatformMediaInfoBarStyle

    func body(content: Content) -> some View {
        content
            .padding(style.contentInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background { barBackground }
    }

    @ViewBuilder
    private var barBackground: some View {
        if reduceTransparency {
            Color(.secondarySystemBackground)
        } else {
            Rectangle()
                .fill(style.material)
        }
    }
}
