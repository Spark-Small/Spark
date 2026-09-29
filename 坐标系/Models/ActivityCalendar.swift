//
//  ActivityCalendar.swift
//  坐标系
//
//  EventKit 写入 / 移除活动提醒；持久化 activityID ↔ eventIdentifier，
//  供详情与参加成功页共用同一套日历状态与符号着色。
//

import EventKit
import Foundation
import SwiftUI
import UIKit
import CoordinateModels

@MainActor
enum ActivityCalendar {
    enum Outcome: Equatable {
        case added(withReminders: Bool)
        case removed
        case accessDenied
        case failed
    }

    /// 日历提醒按钮符号：未加入 `calendar.badge.clock`（􀐭），已加入 `calendar.badge.checkmark`（􀐮）。
    enum Symbol {
        static let off = "calendar.badge.clock"
        static let on = "calendar.badge.checkmark"

        static func systemName(isScheduled: Bool) -> String {
            isScheduled ? on : off
        }
    }

    private static let store = EKEventStore()

    static func isScheduled(activityID: Activity.ID) -> Bool {
        eventIdentifier(for: activityID) != nil
    }

    static func toggle(_ activity: Activity, withReminders: Bool = true) async -> Outcome {
        if isScheduled(activityID: activity.id) {
            return await remove(activityID: activity.id)
        }
        return await add(activity, withReminders: withReminders)
    }

    static func add(_ activity: Activity, withReminders: Bool = true) async -> Outcome {
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
            setEventIdentifier(event.eventIdentifier, for: activity.id)
            return .added(withReminders: withReminders)
        } catch {
            return .failed
        }
    }

    static func remove(activityID: Activity.ID) async -> Outcome {
        guard let identifier = eventIdentifier(for: activityID) else {
            clearEventIdentifier(for: activityID)
            return .removed
        }

        if let event = store.event(withIdentifier: identifier) {
            do {
                try store.remove(event, span: .thisEvent)
            } catch {
                return .failed
            }
        }
        clearEventIdentifier(for: activityID)
        return .removed
    }

    static func removeIfNeeded(activityID: Activity.ID) {
        guard isScheduled(activityID: activityID) else { return }
        Task { @MainActor in
            _ = await remove(activityID: activityID)
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

    static let removedMessage = "已从日历移除提醒"

    static func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Persistence

    private static func eventIdentifier(for activityID: Activity.ID) -> String? {
        ActivityCalendarStore.eventIdentifier(for: activityID)
    }

    private static func setEventIdentifier(_ identifier: String, for activityID: Activity.ID) {
        ActivityCalendarStore.setEventIdentifier(identifier, for: activityID)
    }

    private static func clearEventIdentifier(for activityID: Activity.ID) {
        ActivityCalendarStore.clearEventIdentifier(for: activityID)
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
