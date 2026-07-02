// Module: SparkActivity — Personal inbox sheet (我的活动).

import SparkDesignSystem
import SwiftUI

extension ActivityRootView {
    var myActivitiesSheet: some View {
        NavigationStack(path: $myActivitiesNavigationPath) {
            myActivitiesSheetContent
                .navigationTitle(
                    String(
                        localized: "activity.myActivities.title",
                        defaultValue: "我的活动",
                        comment: "My activities sheet title"
                    )
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "action.close", defaultValue: "关闭", comment: "Close")) {
                            showMyActivities = false
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink {
                            myActivitiesNotificationSettings
                        } label: {
                            Image(systemName: "bell")
                        }
                        .accessibilityLabel(
                            String(
                                localized: "activity.settings.menu",
                                defaultValue: "活动提醒",
                                comment: "Activity reminders entry"
                            )
                        )
                        .accessibilityHint(
                            String(
                                localized: "activity.settings.reminders.hint",
                                defaultValue: "开启后会在活动开始前收到提醒",
                                comment: "Reminders toggle hint"
                            )
                        )
                    }
                }
                .navigationDestination(for: String.self) { activityID in
                    activityDetailView(activityID: activityID, usesTabAccessory: false)
                }
                .sparkPhoneStyleNavigationBar()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var myActivitiesSheetContent: some View {
        // REASONING: Sheet owns its own NavigationStack; inbox filter stays pinned via top accessory, not tab chrome.
        activitiesSegmentContent
            .sparkTabTopAccessory(isEnabled: true) {
                ActivityInboxFilterBar(selection: $viewModel.listFilter)
            }
            .task {
                if viewModel.loadState == .idle {
                    await viewModel.load()
                }
            }
    }

    var myActivitiesNotificationSettings: some View {
        Form {
            ActivityNotificationSettingsSection()
        }
        .navigationTitle(
            String(
                localized: "activity.settings.menu",
                defaultValue: "活动提醒",
                comment: "Activity reminders entry"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    func presentMyActivities() {
        guard isAuthenticated else {
            onSignInRequired?()
            return
        }
        showMyActivities = true
    }
}
