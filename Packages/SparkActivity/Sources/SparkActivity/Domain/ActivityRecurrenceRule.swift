// Module: SparkActivity — Recurring activity schedule rule.

import Foundation

public struct ActivityRecurrenceRule: Hashable, Sendable, Equatable {
    public enum Frequency: String, Sendable, Hashable {
        case weekly
    }

    public enum Weekday: String, Sendable, Hashable, CaseIterable {
        case sunday
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday

        public init?(wireValue: String) {
            switch wireValue.lowercased() {
            case "sunday", "sun": self = .sunday
            case "monday", "mon": self = .monday
            case "tuesday", "tue", "tues": self = .tuesday
            case "wednesday", "wed": self = .wednesday
            case "thursday", "thu", "thur", "thurs": self = .thursday
            case "friday", "fri": self = .friday
            case "saturday", "sat": self = .saturday
            default: return nil
            }
        }

        public init(from date: Date, calendar: Calendar = .current) {
            switch calendar.component(.weekday, from: date) {
            case 1: self = .sunday
            case 2: self = .monday
            case 3: self = .tuesday
            case 4: self = .wednesday
            case 5: self = .thursday
            case 6: self = .friday
            default: self = .saturday
            }
        }

        var calendarWeekday: Int {
            switch self {
            case .sunday: 1
            case .monday: 2
            case .tuesday: 3
            case .wednesday: 4
            case .thursday: 5
            case .friday: 6
            case .saturday: 7
            }
        }

        public func localizedName(calendar: Calendar = .current) -> String {
            var components = DateComponents()
            components.weekday = calendarWeekday
            guard let date = calendar.nextDate(
                after: Date(),
                matching: components,
                matchingPolicy: .nextTime
            ) else {
                return rawValue.capitalized
            }
            return date.formatted(.dateTime.weekday(.wide))
        }
    }

    public let frequency: Frequency
    public let weekday: Weekday
    public let until: Date?

    public init(frequency: Frequency, weekday: Weekday, until: Date? = nil) {
        self.frequency = frequency
        self.weekday = weekday
        self.until = until
    }

    public init?(wireFrequency: String?, wireWeekday: String?, until: Date?) {
        guard wireFrequency == Frequency.weekly.rawValue,
              let wireWeekday,
              let weekday = Weekday(wireValue: wireWeekday) else {
            return nil
        }
        self.frequency = .weekly
        self.weekday = weekday
        self.until = until
    }
}
