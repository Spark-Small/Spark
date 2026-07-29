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
