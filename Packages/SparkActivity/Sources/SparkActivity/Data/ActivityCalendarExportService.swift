// Module: SparkActivity — Add scheduled activity to the system calendar (registrant).

@preconcurrency import EventKit
import Foundation

public enum ActivityCalendarExportResult: Sendable, Equatable {
    case added
    case accessDenied
    case failed(String)
}

public protocol ActivityCalendarExporting: Sendable {
    func addToCalendar(activity: ActivityDetail) async -> ActivityCalendarExportResult
}

/// Writes a one-hour window starting at `startsAt` using venue title only.
@MainActor
public final class ActivityCalendarExportService: ActivityCalendarExporting {
    private let eventStore: EKEventStore

    public init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    public func addToCalendar(activity: ActivityDetail) async -> ActivityCalendarExportResult {
        let granted = await requestAccess()
        guard granted else { return .accessDenied }

        let event = EKEvent(eventStore: eventStore)
        event.title = activity.title
        event.startDate = activity.startsAt
        event.endDate = activity.startsAt.addingTimeInterval(3600)
        if !activity.locationName.isEmpty {
            event.location = activity.locationName
        }
        event.notes = activity.description
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            return .added
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                return false
            }
        }
        return false
    }
}
