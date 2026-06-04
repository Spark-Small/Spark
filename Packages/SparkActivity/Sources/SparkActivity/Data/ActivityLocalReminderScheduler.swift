// Module: SparkActivity — On-device activity reminders when backend push unavailable (Phase 16).

import Foundation
import UserNotifications

public enum ActivityLocalReminderScheduler {
    private static let reminderCategoryID = "spark.activity.reminder"

    private static var isRunningUnitTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }

    public static func syncReminders(for activity: ActivityDetail) async {
        guard !isRunningUnitTests else { return }
        guard ActivityNotificationPreferences.remindersEnabled else {
            await cancelReminders(activityID: activity.id)
            return
        }
        switch activity.rsvpStatus {
        case .going, .maybe, .host:
            await scheduleReminders(for: activity)
        case .invited, .declined, .waitlisted:
            await cancelReminders(activityID: activity.id)
        }
    }

    public static func cancelReminders(activityID: String) async {
        guard !isRunningUnitTests else { return }
        let center = UNUserNotificationCenter.current()
        let ids = identifierPrefixes(activityID: activityID).map { $0 }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func scheduleReminders(for activity: ActivityDetail) async {
        let center = UNUserNotificationCenter.current()
        await cancelReminders(activityID: activity.id)

        let now = Date()
        let intervals: [(suffix: String, offset: TimeInterval)] = [
            ("24h", 24 * 3600),
            ("1h", 3600),
        ]

        for item in intervals {
            let fireDate = activity.startsAt.addingTimeInterval(-item.offset)
            guard fireDate > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = activity.title
            content.body = reminderBody(offset: item.offset, scheduleLine: activity.scheduleLine)
            content.sound = .default
            content.categoryIdentifier = reminderCategoryID
            content.userInfo = [
                "type": "activity.reminder",
                "activity_id": activity.id,
            ]

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "activity_reminder_\(item.suffix)_\(activity.id)",
                content: content,
                trigger: trigger
            )
            // REASONING: Reminder scheduling is best-effort; a duplicate or denied notification must not block RSVP.
            try? await center.add(request)
        }
    }

    private static func reminderBody(offset: TimeInterval, scheduleLine: String) -> String {
        if offset >= 20 * 3600 {
            let format = String(
                localized: "activity.reminder.body.24h",
                defaultValue: "明天见：%@",
                comment: "24h reminder; %@ schedule"
            )
            return String(format: format, locale: .current, scheduleLine)
        }
        let format = String(
            localized: "activity.reminder.body.1h",
            defaultValue: "1 小时后开始：%@",
            comment: "1h reminder; %@ schedule"
        )
        return String(format: format, locale: .current, scheduleLine)
    }

    private static func identifierPrefixes(activityID: String) -> [String] {
        ["activity_reminder_24h_\(activityID)", "activity_reminder_1h_\(activityID)"]
    }
}
