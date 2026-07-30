//
//  PlatformSymbolStyle.swift
//  坐标系
//
//  统一 SF Symbol 渲染：默认 hierarchical；状态 monochrome；
//  角标 palette；内容分类 / 设置入口可用 Apple 原生 multicolor。
//  颜色仅用系统语义色与 PlatformStatus，不引入品牌色板。
//

import SwiftUI

/// SF Symbol 渲染语义（Features 只选 chrome，不手写 rendering mode）。
enum PlatformSymbolChrome: Equatable {
    /// 默认 UI：分层渲染，颜色跟随 tint / foreground。
    case hierarchical

    /// 状态强调：单色 + 语义色（成功 / 警告 / 危险 / tint）。
    case status(Color)

    /// 双层角标：如 `xmark.circle.fill` / `checkmark.circle.fill`。
    case badge(primary: Color, secondary: Color)

    /// Apple 原生多色 glyph（仅用于内容分类、设置入口、空态等）。
    case multicolor

    /// 列表行内操作符：默认 hierarchical + secondary；激活态可走 status。
    case listAction(isActive: Bool = false, activeColor: Color? = nil)
}

extension View {
    /// 统一应用 SF Symbol 渲染与前景色。
    @ViewBuilder
    func platformSymbolStyle(_ chrome: PlatformSymbolChrome) -> some View {
        switch chrome {
        case .hierarchical:
            symbolRenderingMode(.hierarchical)

        case .status(let color):
            symbolRenderingMode(.monochrome)
                .foregroundStyle(color)

        case .badge(let primary, let secondary):
            symbolRenderingMode(.palette)
                .foregroundStyle(primary, secondary)

        case .multicolor:
            symbolRenderingMode(.multicolor)

        case .listAction(let isActive, let activeColor):
            let usesSemanticActive = isActive && activeColor != nil
            symbolRenderingMode(usesSemanticActive ? .monochrome : .hierarchical)
                .foregroundStyle(isActive ? (activeColor ?? .primary) : .secondary)
        }
    }

    /// 列表行内操作符号：body/medium + `PlatformSymbolChrome.listAction`。
    func platformListActionSymbolStyle(
        isActive: Bool = false,
        activeColor: Color? = nil
    ) -> some View {
        font(PlatformListActionSymbol.font)
            .imageScale(PlatformListActionSymbol.imageScale)
            .platformSymbolStyle(.listAction(isActive: isActive, activeColor: activeColor))
    }

    /// 设置 / 资料 / 筛选等内容列表入口：Apple 原生多色。
    /// 勿用于 Toolbar、Tab、Menu、glass 按钮与破坏性角色。
    func platformContentSymbolStyle() -> some View {
        platformSymbolStyle(.multicolor)
    }
}
