// Module: SparkActivity — Stable activity group thread ids (Messages API).

import Foundation

public enum ActivityThreadID {
    public static func make(for activityID: String) -> String {
        "th_activity_\(activityID)"
    }
}

public enum ActivityInviteURL {
    public static func deepLink(activityID: String) -> URL {
        // REASONING: Matches DeepLinkParser `spark://activity/{id}`.
        var components = URLComponents()
        components.scheme = "spark"
        components.host = "activity"
        components.path = "/\(activityID)"
        guard let url = components.url else {
            preconditionFailure("Invalid activity deep link for id: \(activityID)")
        }
        return url
    }

    public static func universalLink(activityID: String) -> URL {
        ActivityLinkConfiguration.webBaseURL.appending(path: "a/\(activityID)")
    }

    public static func shareLink(activityID: String) -> URL {
        if ActivityLinkConfiguration.prefersUniversalLinks {
            universalLink(activityID: activityID)
        } else {
            deepLink(activityID: activityID)
        }
    }

    public static func shareMessage(title: String) -> String {
        let format = String(
            localized: "activity.share.message.format",
            defaultValue: "邀请你参加：%@",
            comment: "Share sheet message; %@ is title"
        )
        return String(format: format, locale: .current, title)
    }

    /// Rich copy for paste / WeChat (time + place + attendance + deep link).
    public static func inviteCopyText(activity: ActivityDetail) -> String {
        let headline = shareMessage(title: activity.title)
        let whenWhere = activity.scheduleLine
        let attendance = attendeeSummary(for: activity)
        let link = shareLink(activityID: activity.id).absoluteString
        let format = String(
            localized: "activity.invite.copy.format",
            defaultValue: "%@\n%@\n%@\n%@",
            comment: "Invite copy; headline, schedule, attendance, link"
        )
        return String(format: format, locale: .current, headline, whenWhere, attendance, link)
    }

    public static func attendeeSummary(for activity: ActivityDetail) -> String {
        if let capacity = activity.capacity {
            let format = String(
                localized: "activity.share.attendance.capacity.format",
                defaultValue: "%1$d/%2$d 人已报名",
                comment: "Share attendance; count and capacity"
            )
            return String(format: format, locale: .current, activity.attendeeCount, capacity)
        }
        let format = String(
            localized: "activity.share.attendance.format",
            defaultValue: "%d 人已报名",
            comment: "Share attendance count"
        )
        return String(format: format, locale: .current, activity.attendeeCount)
    }
}
