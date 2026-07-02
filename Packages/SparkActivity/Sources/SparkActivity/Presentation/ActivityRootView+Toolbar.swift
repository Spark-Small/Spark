// Module: SparkActivity — Activity tab root toolbar (⋯ menu per TAB_SCREENS).

import SparkDesignSystem
import SwiftUI

extension ActivityRootView {
    var activityToolbarButton: some View {
        Button {
            showActivityToolbarActions = true
        } label: {
            Image(systemName: "ellipsis")
                .imageScale(.medium)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            String(
                localized: "activity.toolbar.menu.a11y",
                defaultValue: "活动操作",
                comment: "Activity toolbar menu"
            )
        )
        .accessibilityHint(
            String(
                localized: "activity.toolbar.menu.hint",
                defaultValue: "我的活动、提醒设置或发起活动",
                comment: "Activity toolbar menu hint"
            )
        )
    }

    var activityToolbarActionsSheet: some View {
        NavigationStack {
            List {
                if selectedHomeSegment == .map {
                    Button {
                        selectedHomeSegment = .discover
                        showActivityToolbarActions = false
                    } label: {
                        Label(
                            ActivityHomeSegment.discover.localizedTitle,
                            systemImage: "safari"
                        )
                    }
                }

                Button {
                    showActivityToolbarActions = false
                    presentMyActivities()
                } label: {
                    Label(
                        String(
                            localized: "activity.myActivities.toolbar",
                            defaultValue: "我的活动",
                            comment: "My activities toolbar button"
                        ),
                        systemImage: "tray.full"
                    )
                }

                Button {
                    showActivityToolbarActions = false
                    showActivityReminders = true
                } label: {
                    Label(
                        String(
                            localized: "activity.settings.menu",
                            defaultValue: "活动提醒",
                            comment: "Activity reminders entry"
                        ),
                        systemImage: "bell"
                    )
                }

                Button {
                    showActivityToolbarActions = false
                    presentCreateActivityFromToolbar()
                } label: {
                    Label(
                        String(
                            localized: "activity.create.host.cta",
                            defaultValue: "发起活动",
                            comment: "Host a new activity from toolbar menu"
                        ),
                        systemImage: "plus.circle"
                    )
                }
            }
            .navigationTitle(
                String(
                    localized: "activity.toolbar.menu.a11y",
                    defaultValue: "活动操作",
                    comment: "Activity toolbar menu"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.close", defaultValue: "关闭", comment: "Close")) {
                        showActivityToolbarActions = false
                    }
                }
            }
            .sparkPhoneStyleNavigationBar()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    var activityRemindersSheet: some View {
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.done", defaultValue: "完成", comment: "Done")) {
                        showActivityReminders = false
                    }
                }
            }
            .sparkPhoneStyleNavigationBar()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    func presentCreateActivityFromToolbar() {
        if isAuthenticated {
            pendingCreateActivityDraft = CreateActivityDraft()
        } else {
            onSignInRequiredForCreate?(CreateActivityDraft())
        }
    }
}
