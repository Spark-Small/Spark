//
//  PlatformSheet.swift
//  坐标系
//
//  按 Apple 官方 sheet 示例统一呈现：
//  https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:)
//
//  - form：发布/编辑（.large）
//  - filter：筛选/轻设置（.medium + .large）
//  - browser：列表/资料/可滚动内容（.medium + .large）
//  - confirm：成功/短确认（.medium）
//  - action：固定高度动作面板
//

import SwiftUI

enum PlatformSheetKind: Equatable {
    /// 发布 / 编辑表单
    case form
    /// 筛选、轻量设置
    case filter
    /// 列表、资料、可滚动内容
    case browser
    /// 成功、短确认
    case confirm
    /// 动作选择（如导航 App 列表）
    case action(height: CGFloat)
}

extension View {
    /// 统一 sheet 高度档位与拖动指示器；支付等流程可禁用下滑关闭。
    func platformSheet(
        _ kind: PlatformSheetKind,
        interactiveDismissDisabled: Bool = false
    ) -> some View {
        modifier(
            PlatformSheetModifier(
                kind: kind,
                interactiveDismissDisabled: interactiveDismissDisabled
            )
        )
    }
}

private struct PlatformSheetModifier: ViewModifier {
    let kind: PlatformSheetKind
    let interactiveDismissDisabled: Bool

    func body(content: Content) -> some View {
        content
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(interactiveDismissDisabled)
    }

    private var detents: Set<PresentationDetent> {
        switch kind {
        case .form:
            [.large]
        case .filter, .browser:
            [.medium, .large]
        case .confirm:
            [.medium]
        case .action(let height):
            [.height(height)]
        }
    }
}
