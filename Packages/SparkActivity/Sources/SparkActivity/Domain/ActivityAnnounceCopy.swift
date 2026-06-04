// Module: SparkActivity — Host broadcast / reschedule system messages (Phase 22).

import Foundation

public enum ActivityAnnounceCopy {
    public static func systemMessage(activityTitle: String, body: String) -> String {
        let format = String(
            localized: "activity.announce.system.format",
            defaultValue: "【活动通知 · %@】%@",
            comment: "Group system message; title + body"
        )
        return String(format: format, locale: .current, activityTitle, body)
    }

    public static func rescheduleMessage(activityTitle: String, scheduleLine: String) -> String {
        let format = String(
            localized: "activity.reschedule.system.format",
            defaultValue: "主办更新了「%@」的时间：%@",
            comment: "Reschedule system message"
        )
        return String(format: format, locale: .current, activityTitle, scheduleLine)
    }
}
