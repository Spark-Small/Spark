// Module: SparkAppShell — Liquid Glass TabView with buddy discovery tab (iOS 18+).

import SwiftUI

extension SparkMainTabView {
    @available(iOS 18.0, *)
    @ViewBuilder
    var modernTabView: some View {
        TabView(selection: tabSelection) {
            Tab(SparkTab.activity.title, systemImage: SparkTab.activity.systemImage, value: SparkTab.activity) {
                activityTabRoot
            }

            Tab(SparkTab.buddy.title, systemImage: SparkTab.buddy.systemImage, value: SparkTab.buddy) {
                buddyTabRoot
            }

            Tab(SparkTab.community.title, systemImage: SparkTab.community.systemImage, value: SparkTab.community) {
                communityTabRoot
            }

            Tab(SparkTab.messages.title, systemImage: SparkTab.messages.systemImage, value: SparkTab.messages) {
                messagesTabWithBadge
            }

            Tab(SparkTab.profile.title, systemImage: SparkTab.profile.systemImage, value: SparkTab.profile) {
                profileTabRoot
            }
        }
        .sparkMainTabChrome(
            activityChrome: activityTabChrome,
            communityChrome: communityTabChrome,
            selectedTab: router.selectedTab,
            onCreateActivity: { presentCreateActivity() }
        )
    }
}
