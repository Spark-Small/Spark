// Module: SparkAppShell — Legacy TabView children (iOS 17).

import SwiftUI

extension SparkMainTabView {
    @ViewBuilder
    var legacyTabContent: some View {
        activityTabRoot
            .tabItem { tabLabel(for: .activity) }
            .tag(SparkTab.activity)

        buddyTabRoot
            .tabItem { tabLabel(for: .buddy) }
            .tag(SparkTab.buddy)

        communityTabRoot
            .tabItem { tabLabel(for: .community) }
            .tag(SparkTab.community)

        messagesTabWithBadge
            .tabItem { tabLabel(for: .messages) }
            .tag(SparkTab.messages)

        profileTabRoot
            .tabItem { tabLabel(for: .profile) }
            .tag(SparkTab.profile)
    }

    var legacyTabView: some View {
        TabView(selection: tabSelection) {
            legacyTabContent
        }
        .sparkMainTabChrome(
            activityChrome: activityTabChrome,
            communityChrome: communityTabChrome,
            selectedTab: router.selectedTab,
            onCreateActivity: { presentCreateActivity() }
        )
    }
}
