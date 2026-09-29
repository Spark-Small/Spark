//
//  ActivityCalendarStore.swift
//  坐标系
//
//  活动 ↔ EventKit eventIdentifier 映射持久化（可单测）。
//

import Foundation
import CoordinateModels

@MainActor
enum ActivityCalendarStore {
    private static let mappingKey = "activity.calendarEventIdentifiers"

    static func eventIdentifier(for activityID: Activity.ID) -> String? {
        mapping()[activityID.uuidString]
    }

    static func setEventIdentifier(_ identifier: String, for activityID: Activity.ID) {
        var next = mapping()
        next[activityID.uuidString] = identifier
        saveMapping(next)
    }

    static func clearEventIdentifier(for activityID: Activity.ID) {
        var next = mapping()
        next.removeValue(forKey: activityID.uuidString)
        saveMapping(next)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: mappingKey)
    }

    private static func mapping() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: mappingKey) as? [String: String] ?? [:]
    }

    private static func saveMapping(_ mapping: [String: String]) {
        UserDefaults.standard.set(mapping, forKey: mappingKey)
    }
}
