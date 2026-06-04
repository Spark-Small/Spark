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
        URL(string: "spark://activity/\(activityID)")!
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

    /// Rich copy for paste / WeChat (time + place + deep link).
    public static func inviteCopyText(activity: ActivityDetail) -> String {
        let headline = shareMessage(title: activity.title)
        let whenWhere = activity.scheduleLine
        let link = shareLink(activityID: activity.id).absoluteString
        let format = String(
            localized: "activity.invite.copy.format",
            defaultValue: "%@\n%@\n%@",
            comment: "Invite copy; three lines: headline, schedule, link"
        )
        return String(format: format, locale: .current, headline, whenWhere, link)
    }
}
