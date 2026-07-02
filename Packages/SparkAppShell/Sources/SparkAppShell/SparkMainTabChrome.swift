// Module: SparkAppShell — Tab bar minimize + per-tab bottom accessories (iOS 26+).

import SparkActivity
import SparkCommunity
import SwiftUI

private struct SparkMainTabChromeModifier: ViewModifier {
    @Bindable var activityChrome: ActivityTabChrome
    @Bindable var communityChrome: CommunityTabChrome
    let selectedTab: SparkTab
    let onCreateActivity: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content
                .tabBarMinimizeBehavior(.onScrollDown)
                .tabViewBottomAccessory(isEnabled: isBottomAccessoryEnabled) {
                    tabBottomAccessory
                }
        } else {
            content
        }
    }

    private var isBottomAccessoryEnabled: Bool {
        switch selectedTab {
        case .activity:
            activityChrome.isBottomAccessoryEnabled
        case .community:
            communityChrome.isBottomAccessoryEnabled
        default:
            false
        }
    }

    @ViewBuilder
    private var tabBottomAccessory: some View {
        if #available(iOS 26.1, *) {
            switch selectedTab {
            case .activity:
                ActivityTabBottomAccessory(
                    chrome: activityChrome,
                    fallback: onCreateActivity
                )
            case .community:
                CommunityComposePostAccessory(
                    kind: communityChrome.kind,
                    isLoading: communityChrome.isLoading
                ) {
                    communityChrome.actionHandler?()
                }
            default:
                EmptyView()
            }
        }
    }
}

extension View {
    /// Scroll-down tab bar minimize; Activity discover + Community feed show contextual bottom CTAs.
    func sparkMainTabChrome(
        activityChrome: ActivityTabChrome,
        communityChrome: CommunityTabChrome,
        selectedTab: SparkTab,
        onCreateActivity: @escaping () -> Void
    ) -> some View {
        modifier(
            SparkMainTabChromeModifier(
                activityChrome: activityChrome,
                communityChrome: communityChrome,
                selectedTab: selectedTab,
                onCreateActivity: onCreateActivity
            )
        )
    }
}
