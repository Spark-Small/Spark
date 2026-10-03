//
//  PlatformTabRootChrome.swift
//  坐标系
//
//  五 Tab 根顶栏统一契约：inlineLarge + soft 顶边 + 栏材质联动；
//  不压制 compact title；活动/搭子可选 toolbarTitleMenu。
//

import SwiftUI

extension View {
    /// Tab 根 ScrollView / List：系统标题 + 栏材质随滚动联动；可选顶边 soft edge。
    func platformTabRootScrollChrome(
        title: String,
        titleDisplayMode: ToolbarTitleDisplayMode = .inlineLarge,
        softTopEdge: Bool = true
    ) -> some View {
        contentMargins(.top, 0, for: .scrollContent)
            .modifier(PlatformTabRootSoftTopEdgeModifier(enabled: softTopEdge))
            .navigationTitle(title)
            .toolbarTitleDisplayMode(titleDisplayMode)
            .toolbarBackground(.automatic, for: .navigationBar)
            .toolbarBackgroundVisibility(.automatic, for: .navigationBar)
    }

    /// Tab 根 List：可选 compact section spacing。
    func platformTabRootListChrome(
        title: String,
        compactSections: Bool = false,
        titleDisplayMode: ToolbarTitleDisplayMode = .inlineLarge,
        softTopEdge: Bool = true
    ) -> some View {
        modifier(
            PlatformTabRootListChromeModifier(
                title: title,
                compactSections: compactSections,
                titleDisplayMode: titleDisplayMode,
                softTopEdge: softTopEdge
            )
        )
    }

    /// Tab 根页可点标题菜单（搭子模式等）。
    func platformTabRootTitleMenu<MenuContent: View>(
        @ViewBuilder menu: () -> MenuContent
    ) -> some View {
        toolbarTitleMenu(content: menu)
    }

    /// Tab 根页 toolbar（不注入空 principal）。图标须 `.platformNavigationBarItemChrome()`；分组用 `ToolbarItemGroup` + `ToolbarSpacer`。
    func platformTabRootToolbar<Content: ToolbarContent>(
        @ToolbarContentBuilder content: () -> Content
    ) -> some View {
        toolbar(content: content)
    }
}

private struct PlatformTabRootSoftTopEdgeModifier: ViewModifier {
    var enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            content
        }
    }
}

private struct PlatformTabRootListChromeModifier: ViewModifier {
    let title: String
    let compactSections: Bool
    var titleDisplayMode: ToolbarTitleDisplayMode = .inlineLarge
    var softTopEdge: Bool = true

    func body(content: Content) -> some View {
        Group {
            if compactSections {
                content.listSectionSpacing(.compact)
            } else {
                content
            }
        }
        .platformTabRootScrollChrome(
            title: title,
            titleDisplayMode: titleDisplayMode,
            softTopEdge: softTopEdge
        )
    }
}
