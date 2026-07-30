//
//  BuddyZoomNavigation.swift
//  坐标系
//
//  选人卡 → 资料：NavigationLink + matchedTransitionSource + zoom
//

import SwiftUI

extension View {
    func buddyZoomTransitionSource(
        id: DiscoverBuddyItem.ID,
        in namespace: Namespace.ID
    ) -> some View {
        matchedTransitionSource(id: id, in: namespace) { source in
            source.clipShape(PlatformMetrics.cardShape)
        }
    }

    func buddyZoomNavigationTransition(
        id: DiscoverBuddyItem.ID,
        in namespace: Namespace.ID
    ) -> some View {
        navigationTransition(.zoom(sourceID: id, in: namespace))
    }

    /// 栈根注册：资料页目的地 + zoom，并向栈内注入 namespace
    func buddyZoomNavigationDestination(
        namespace: Namespace.ID
    ) -> some View {
        self
            .environment(\.buddyZoomNamespace, namespace)
            .navigationDestination(for: DiscoverBuddyItem.self) { item in
                BuddyDetailRouteView(item: item)
                    .buddyZoomNavigationTransition(id: item.id, in: namespace)
                    .environment(\.buddyZoomNamespace, namespace)
            }
    }

    /// 二级页：外层栈已注册就不再重复注册（重复时只有最靠近栈根的生效）
    func buddyDetailNavigationDestinationIfNeeded() -> some View {
        modifier(BuddyDetailStackRegistration())
    }
}

/// 当前导航栈的搭子 zoom namespace
private struct BuddyZoomNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var buddyZoomNamespace: Namespace.ID? {
        get { self[BuddyZoomNamespaceKey.self] }
        set { self[BuddyZoomNamespaceKey.self] = newValue }
    }
}

private struct BuddyDetailStackRegistration: ViewModifier {
    @Environment(\.buddyZoomNamespace) private var inherited

    func body(content: Content) -> some View {
        if inherited == nil {
            content.navigationDestination(for: DiscoverBuddyItem.self) { item in
                BuddyDetailRouteView(item: item)
            }
        } else {
            content
        }
    }
}

struct BuddyZoomNavigationLink<Label: View>: View {
    let item: DiscoverBuddyItem
    var namespace: Namespace.ID
    @ViewBuilder var label: () -> Label

    var body: some View {
        NavigationLink(value: item) {
            label()
        }
        .buttonStyle(.plain)
        .buddyZoomTransitionSource(id: item.id, in: namespace)
    }
}
