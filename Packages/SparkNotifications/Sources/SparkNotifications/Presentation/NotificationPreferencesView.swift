// Module: SparkNotifications — Global notification preferences UI.

import SwiftUI

public struct NotificationPreferencesView: View {
    @State private var matchEnabled = SparkNotificationPreferences.matchEnabled
    @State private var messageEnabled = SparkNotificationPreferences.messageEnabled
    @State private var activityEnabled = SparkNotificationPreferences.activityEnabled

    public init() {}

    public var body: some View {
        Form {
            Section {
                Toggle(
                    String(
                        localized: "notifications.match",
                        defaultValue: "配对与喜欢",
                        comment: "Match notifications"
                    ),
                    isOn: $matchEnabled
                )
                .onChange(of: matchEnabled) { _, value in
                    SparkNotificationPreferences.matchEnabled = value
                }
                Toggle(
                    String(
                        localized: "notifications.messages",
                        defaultValue: "新消息",
                        comment: "Message notifications"
                    ),
                    isOn: $messageEnabled
                )
                .onChange(of: messageEnabled) { _, value in
                    SparkNotificationPreferences.messageEnabled = value
                }
                Toggle(
                    String(
                        localized: "notifications.activity",
                        defaultValue: "活动更新",
                        comment: "Activity notifications"
                    ),
                    isOn: $activityEnabled
                )
                .onChange(of: activityEnabled) { _, value in
                    SparkNotificationPreferences.activityEnabled = value
                }
            } footer: {
                Text(
                    String(
                        localized: "notifications.settings.footer",
                        defaultValue: "关闭后仍可在系统设置中管理 Spark 的通知权限。",
                        comment: "Notification settings footer"
                    )
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotificationPreferencesView()
    }
}
