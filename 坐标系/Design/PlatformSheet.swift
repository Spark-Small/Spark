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
//  - navigationPicker：导航 App 等短 List（.medium 单档，同系统半屏规范）
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
    /// 导航 App 等短 List（系统 .medium 单档，不可拉高）
    case navigationPicker
    /// 动作选择（固定高度动作面板）
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
        case .confirm, .navigationPicker:
            [.medium]
        case .action(let height):
            [.height(height)]
        }
    }
}

// MARK: - Toolbar chrome

extension View {
    /// Sheet 左上角：`cancellationAction`（取消 / 关闭 / 稍后）。
    func platformSheetCancellationToolbar(
        _ title: String,
        action: (() -> Void)? = nil
    ) -> some View {
        modifier(PlatformSheetCancellationToolbar(title: title, action: action))
    }

    /// Sheet 右上角：`confirmationAction`（完成 / 保存 / 发送）。
    func platformSheetConfirmationToolbar(
        _ title: String = "完成",
        isEnabled: Bool = true,
        action: (() -> Void)? = nil
    ) -> some View {
        modifier(
            PlatformSheetConfirmationToolbar(
                title: title,
                isEnabled: isEnabled,
                action: action
            )
        )
    }
}

private struct PlatformSheetCancellationToolbar: ViewModifier {
    let title: String
    var action: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(title) {
                    if let action {
                        action()
                    } else {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct PlatformSheetConfirmationToolbar: ViewModifier {
    let title: String
    var isEnabled: Bool
    var action: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(title) {
                    if let action {
                        action()
                    } else {
                        dismiss()
                    }
                }
                .fontWeight(.semibold)
                .disabled(!isEnabled)
            }
        }
    }
}
