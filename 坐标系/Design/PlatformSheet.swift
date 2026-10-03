//
//  PlatformSheet.swift
//  坐标系
//
//  按 Apple 官方 sheet 示例统一呈现：
//  https://developer.apple.com/documentation/swiftui/view/presentationdetents(_:)
//  https://developer.apple.com/documentation/swiftui/view/presentationsizing(_:)
//
//  - form：发布/编辑（.large）
//  - filter：筛选/轻设置（.medium + .large）
//  - browser：列表/资料/可滚动内容（.medium + .large）
//  - confirm：成功/短确认（.medium）
//  - navigationPicker：导航 App 等短 List（.medium 单档，同系统半屏规范）
//  - fitted：按内容理想尺寸（`presentationSizing(.fitted)`）
//  - light：轻操作短面板（传入 `.height(...)` / `.fraction(...)`）
//  - action：固定高度动作面板（等同 `.light(.height)`）
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
    /// 导航 App 等短 List（系统 `.medium` 单档，不可拉高）
    case navigationPicker
    /// 按内容理想尺寸（系统 `presentationSizing(.fitted)`）
    case fitted
    /// 轻操作短面板（系统 `.height(...)` / `.fraction(...)`）
    case light(PresentationDetent)
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

    @ViewBuilder
    func body(content: Content) -> some View {
        switch kind {
        case .fitted:
            // Apple: presentationSizing(.fitted) — 高度由内容理想尺寸决定，不设 detent。
            content
                .presentationSizing(.fitted)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(interactiveDismissDisabled)
        default:
            content
                .presentationDetents(detents)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(interactiveDismissDisabled)
        }
    }

    private var detents: Set<PresentationDetent> {
        switch kind {
        case .form:
            [.large]
        case .filter, .browser:
            [.medium, .large]
        case .confirm, .navigationPicker:
            [.medium]
        case .fitted:
            []
        case .light(let detent):
            [detent]
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
    /// - Parameter emphasizesWhenEnabled: 可点时用 prominent 高亮，提示主操作已就绪。
    func platformSheetConfirmationToolbar(
        _ title: String = "完成",
        isEnabled: Bool = true,
        emphasizesWhenEnabled: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        modifier(
            PlatformSheetConfirmationToolbar(
                title: title,
                isEnabled: isEnabled,
                emphasizesWhenEnabled: emphasizesWhenEnabled,
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
    var emphasizesWhenEnabled: Bool
    var action: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .confirmationAction) {
                let button = Button(title) {
                    if let action {
                        action()
                    } else {
                        dismiss()
                    }
                }
                .fontWeight(.semibold)
                .disabled(!isEnabled)

                if emphasizesWhenEnabled, isEnabled {
                    button.buttonStyle(.borderedProminent)
                } else {
                    button
                }
            }
        }
    }
}
