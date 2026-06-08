// Module: SparkActivity — Calendar export user feedback strings.

import Foundation

enum ActivityCalendarFeedback {
    static func message(for result: ActivityCalendarExportResult) -> String {
        switch result {
        case .added:
            String(
                localized: "activity.calendar.added",
                defaultValue: "已加入日历",
                comment: "Calendar feedback"
            )
        case .accessDenied:
            String(
                localized: "activity.calendar.denied",
                defaultValue: "请在系统设置中允许访问日历。",
                comment: "Calendar feedback"
            )
        case let .failed(description):
            description
        }
    }
}
