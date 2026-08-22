//
//  ActivityCalendar.swift
//  坐标系
//

import EventKit
import Foundation
import SwiftUI
import UIKit

enum ActivityCalendar {
    enum Outcome: Equatable {
        case added(withReminders: Bool)
        case accessDenied
        case failed
    }

    /// 写入日历并设置开场前提醒（适合各年龄：提前 1 天 + 提前 1 小时）
    static func add(_ activity: Activity, withReminders: Bool = true) async -> Outcome {
        let store = EKEventStore()

        if isAccessDenied {
            return .accessDenied
        }

        if !canWriteEvents {
            do {
                let granted: Bool
                if #available(iOS 17.0, *) {
                    granted = try await store.requestFullAccessToEvents()
                } else {
                    granted = try await store.requestAccess(to: .event)
                }
                guard granted, canWriteEvents else {
                    return isAccessDenied ? .accessDenied : .failed
                }
            } catch {
                return .failed
            }
        }

        do {
            let event = EKEvent(eventStore: store)
            event.title = activity.title
            event.location = activity.location
            event.notes = "\(activity.summary)\n费用：\(activity.fee)\n发起人：\(activity.hostName)"
            event.startDate = activity.date
            event.endDate = activity.date.addingTimeInterval(3600 * 2)
            event.calendar = store.defaultCalendarForNewEvents

            if withReminders {
                event.alarms = [
                    EKAlarm(relativeOffset: -3600),
                    EKAlarm(relativeOffset: -3600 * 24)
                ]
            }

            try store.save(event, span: .thisEvent)
            return .added(withReminders: withReminders)
        } catch {
            return .failed
        }
    }

    static var isAccessDenied: Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .denied, .restricted:
            return true
        default:
            return false
        }
    }

    static var canWriteEvents: Bool {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            return true
        case .fullAccess, .writeOnly:
            if #available(iOS 17.0, *) {
                return true
            }
            return false
        default:
            return false
        }
    }

    static func successMessage(withReminders: Bool) -> String {
        withReminders ? "已添加至日历，开场前将提醒你" : "已添加至日历"
    }

    static func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

extension View {
    func activityCalendarAccessAlert(isPresented: Binding<Bool>) -> some View {
        alert(
            ActivityDetailCopy.calendarAccessDeniedTitle,
            isPresented: isPresented
        ) {
            Button(ActivityDetailCopy.calendarOpenSettings) {
                ActivityCalendar.openSystemSettings()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(ActivityDetailCopy.calendarAccessDeniedMessage)
        }
    }
}
