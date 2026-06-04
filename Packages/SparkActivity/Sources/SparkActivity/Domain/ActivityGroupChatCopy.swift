// Module: SparkActivity — Copy for activity group threads in Messages.

import Foundation

public enum ActivityGroupChatCopy {
    public static func displayName(activityTitle: String) -> String {
        let format = String(
            localized: "activity.groupChat.name.format",
            defaultValue: "%@ · 群",
            comment: "Activity group thread name; %@ is title"
        )
        return String(format: format, locale: .current, activityTitle)
    }

    public static func welcomeMessage(activityTitle: String) -> String {
        let format = String(
            localized: "activity.groupChat.welcome.format",
            defaultValue: "欢迎加入「%@」活动群，集合时间与地点见活动详情。",
            comment: "Welcome message; %@ is title"
        )
        return String(format: format, locale: .current, activityTitle)
    }
}
