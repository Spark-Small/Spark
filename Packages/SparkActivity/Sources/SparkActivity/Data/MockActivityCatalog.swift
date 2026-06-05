// Module: SparkActivity — Shared mock invitations (list + detail).

import Foundation

enum MockActivityCatalog {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        return calendar
    }()

    static func allDetails() -> [ActivityDetail] {
        let saturday = nextWeekday(.saturday, hour: 9, minute: 30)
        let tonight = today(hour: 19, minute: 0)
        let tomorrowMorning = tomorrow(hour: 7, minute: 0)
        let lastWeek = daysAgo(5, hour: 14, minute: 0)

        return seededDetails(
            saturday: saturday,
            tonight: tonight,
            tomorrowMorning: tomorrowMorning,
            lastWeek: lastWeek,
            sundayAfternoon: nextWeekday(.sunday, hour: 15, minute: 0)
        )
    }

    static func detail(id: String) -> ActivityDetail? {
        allDetails().first { $0.id == id }
    }

    private static func today(hour: Int, minute: Int) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? Date()
    }

    private static func tomorrow(hour: Int, minute: Int) -> Date {
        let base = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var components = calendar.dateComponents([.year, .month, .day], from: base)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? base
    }

    private static func daysAgo(_ days: Int, hour: Int, minute: Int) -> Date {
        let base = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var components = calendar.dateComponents([.year, .month, .day], from: base)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components) ?? base
    }

    private static func nextWeekday(_ weekday: Weekday, hour: Int, minute: Int) -> Date {
        var date = Date()
        for _ in 0 ..< 14 {
            if calendar.component(.weekday, from: date) == weekday.rawValue {
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = hour
                components.minute = minute
                if let scheduled = calendar.date(from: components), scheduled > Date() {
                    return scheduled
                }
            }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        return tomorrow(hour: hour, minute: minute)
    }

    private enum Weekday: Int {
        case sunday = 1
        case saturday = 7
    }
}
