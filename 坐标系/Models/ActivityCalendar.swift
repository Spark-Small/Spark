//
//  ActivityCalendar.swift
//  坐标系
//

import EventKit
import Foundation

enum ActivityCalendar {
    /// 写入日历并设置开场前提醒（适合各年龄：提前 1 天 + 提前 1 小时）
    static func add(_ activity: Activity, withReminders: Bool = true) async -> String {
        let store = EKEventStore()
        do {
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await store.requestFullAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            guard granted else { return "未获得日历权限，可在设置中开启" }

            let event = EKEvent(eventStore: store)
            event.title = activity.title
            event.location = activity.location
            event.notes = "\(activity.summary)\n费用：\(activity.fee)\n发起人：\(activity.hostName)"
            event.startDate = activity.date
            event.endDate = activity.date.addingTimeInterval(3600 * 2)
            event.calendar = store.defaultCalendarForNewEvents

            if withReminders {
                event.alarms = [
                    EKAlarm(relativeOffset: -3600),        // 提前 1 小时
                    EKAlarm(relativeOffset: -3600 * 24)    // 提前 1 天
                ]
            }

            try store.save(event, span: .thisEvent)
            return withReminders ? "已添加至日历，开场前将提醒你" : "已添加至日历"
        } catch {
            return "暂时无法写入日历，请稍后重试"
        }
    }
}
