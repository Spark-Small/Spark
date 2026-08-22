//
//  BuddyZoomNavigation.swift
//  坐标系
//
//  选人卡 → 资料：NavigationLink + matchedTransitionSource + zoom
//  用 BuddyZoomRoute 与 CircleBrowseRoute 分流，同一 Tab 单层栈共存。
//

import SwiftUI

/// 搭子发现 Zoom 栈路由（勿与 CircleBrowseRoute.member 混用）
struct BuddyZoomRoute: Hashable {
    let item: DiscoverBuddyItem
}

/// Zoom 源 ID：itemID + slot 防止同一人出现在多个货架时的命名空间冲突
struct BuddyZoomSource: Hashable {
    let itemID: DiscoverBuddyItem.ID
    var slot: String
}

extension View {
    func buddyZoomTransitionSource(
        _ source: BuddyZoomSource,
        in namespace: Namespace.ID
    ) -> some View {
        matchedTransitionSource(id: source, in: namespace) { config in
            config.clipShape(PlatformMetrics.cardShape)
        }
    }

    func buddyZoomNavigationTransition(
        _ source: BuddyZoomSource,
        in namespace: Namespace.ID
    ) -> some View {
        navigationTransition(.zoom(sourceID: source, in: namespace))
    }

    /// Tab 栈根：Zoom 资料页目的地（单层栈，与 circleBrowse 并列注册）
    func buddyZoomNavigationDestination(
        namespace: Namespace.ID
    ) -> some View {
        modifier(BuddyZoomDestination(namespace: namespace))
    }
}

private struct BuddyZoomDestinationKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var hasBuddyZoomDestination: Bool {
        get { self[BuddyZoomDestinationKey.self] }
        set { self[BuddyZoomDestinationKey.self] = newValue }
    }
}

private struct BuddyZoomDestination: ViewModifier {
    let namespace: Namespace.ID
    @Environment(\.hasBuddyZoomDestination) private var registered

    func body(content: Content) -> some View {
        if registered {
            content
        } else {
            content
                .environment(\.buddyZoomNamespace, namespace)
                .environment(\.hasBuddyZoomDestination, true)
                .navigationDestination(for: BuddyZoomRoute.self) { route in
                    BuddyDetailRouteView(item: route.item)
                        .buddyZoomNavigationTransition(
                            BuddyZoomSource(itemID: route.item.id, slot: "detail"),
                            in: namespace
                        )
                        .toolbarVisibility(.hidden, for: .tabBar)
                        .environment(\.buddyZoomNamespace, namespace)
                }
                .circleBrowseNavigationDestination()
        }
    }
}

private struct BuddyZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var buddyZoomNamespace: Namespace.ID? {
        get { self[BuddyZoomNamespaceKey.self] }
        set { self[BuddyZoomNamespaceKey.self] = newValue }
    }
}

/// Zoom 入口：`NavigationLink(value:)` + `matchedTransitionSource` 转场。
struct BuddyZoomNavigationLink<Label: View>: View {
    let item: DiscoverBuddyItem
    var slot: String = "browse"
    var namespace: Namespace.ID
    @ViewBuilder var label: () -> Label

    var body: some View {
        NavigationLink(value: BuddyZoomRoute(item: item)) {
            label()
        }
        .buttonStyle(.plain)
        .buddyZoomTransitionSource(
            BuddyZoomSource(itemID: item.id, slot: slot),
            in: namespace
        )
    }
}
