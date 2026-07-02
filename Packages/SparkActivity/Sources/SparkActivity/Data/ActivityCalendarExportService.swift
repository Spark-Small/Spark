// Module: SparkActivity — Add scheduled activity to the system calendar (registrant).

@preconcurrency import EventKit
import Foundation
import SparkCore

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
        let source = SparkPermissionTelemetry.Source.activityAddToCalendar
        let status = EKEventStore.authorizationStatus(for: .event)
        SparkPermissionTelemetry.statusChecked(
            permission: .calendar,
            source: source,
            status: SparkPermissionTelemetry.calendarStatus(from: status)
        )

        if #available(iOS 17.0, *) {
            if status == .notDetermined {
                SparkPermissionTelemetry.promptRequested(permission: .calendar, source: source)
            }
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                if status == .notDetermined {
                    SparkPermissionTelemetry.promptResult(
                        permission: .calendar,
                        source: source,
                        outcome: SparkPermissionTelemetry.calendarOutcome(
                            granted: granted,
                            status: EKEventStore.authorizationStatus(for: .event)
                        )
                    )
                }
                return granted
            } catch {
                if status == .notDetermined {
                    SparkPermissionTelemetry.promptResult(
                        permission: .calendar,
                        source: source,
                        outcome: .denied
                    )
                }
                return false
            }
        }
        return false
    }
}
