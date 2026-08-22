//
//  PlatformTabRootChrome.swift
//  坐标系
//
//  Tab 根页顶栏：inlineLarge 大标题 + principal 占位 + 可选标题菜单。
//

import SwiftUI

/// Tab 根页顶栏：suppress 滚动后中间紧凑标题。
struct PlatformTabRootTitlePrincipal: ToolbarContent {
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(verbatim: "")
                .accessibilityHidden(true)
        }
    }
}

extension View {
    /// Tab 根 ScrollView / List：顶栏标题 + scroll edge。
    func platformTabRootScrollChrome(title: String) -> some View {
        contentMargins(.top, 0, for: .scrollContent)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inlineLarge)
    }

    /// Tab 根 List：可选 compact section spacing（「我的」）。
    func platformTabRootListChrome(title: String, compactSections: Bool = false) -> some View {
        modifier(PlatformTabRootListChromeModifier(title: title, compactSections: compactSections))
    }

    /// Tab 根页可点标题菜单（活动分类等）。
    func platformTabRootTitleMenu<MenuContent: View>(
        @ViewBuilder menu: () -> MenuContent
    ) -> some View {
        toolbarTitleMenu(content: menu)
    }

    /// Tab 根页 toolbar：自动注入 `PlatformTabRootTitlePrincipal`。
    func platformTabRootToolbar<Content: ToolbarContent>(
        @ToolbarContentBuilder content: () -> Content
    ) -> some View {
        toolbar {
            PlatformTabRootTitlePrincipal()
            content()
        }
    }
}

private struct PlatformTabRootListChromeModifier: ViewModifier {
    let title: String
    let compactSections: Bool

    func body(content: Content) -> some View {
        Group {
            if compactSections {
                content.listSectionSpacing(.compact)
            } else {
                content
            }
        }
        .platformTabRootScrollChrome(title: title)
    }
}
