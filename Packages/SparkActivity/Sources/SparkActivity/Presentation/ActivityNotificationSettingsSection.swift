// Module: SparkActivity — Activity reminder toggle (Phase 16).

import SwiftUI

public struct ActivityNotificationSettingsSection: View {
    @State private var remindersEnabled = ActivityNotificationPreferences.remindersEnabled

    public init() {}

    public var body: some View {
        Section {
            Toggle(
                String(
                    localized: "activity.settings.reminders",
                    defaultValue: "活动提醒",
                    comment: "Activity reminders toggle"
                ),
                isOn: $remindersEnabled
            )
            .onChange(of: remindersEnabled) { _, enabled in
                ActivityNotificationPreferences.remindersEnabled = enabled
                if enabled {
                    ActivityNotificationRegistrar.registerIfNeeded()
                }
            }
            .accessibilityHint(
                String(
                    localized: "activity.settings.reminders.hint",
                    defaultValue: "开启后会在活动开始前收到提醒",
                    comment: "Reminders toggle hint"
                )
            )
        } footer: {
            Text(
                String(
                    localized: "activity.settings.reminders.footer",
                    defaultValue: "报名后可在活动开始前 24 小时与 1 小时收到提醒；主办改期或取消也会通知。",
                    comment: "Reminders footer"
                )
            )
        }
    }
}

#Preview {
    Form {
        ActivityNotificationSettingsSection()
    }
}
