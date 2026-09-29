//
//  FilterActivitiesBrowseUseCase.swift
//  CoordinateDomain
//

import Foundation
import CoordinateModels

public struct FilterActivitiesBrowseUseCase: Sendable {
    public init() {}

    public func execute(activities: [Activity], criteria: ActivityBrowseCriteria) -> [Activity] {
        let query = criteria.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return activities.filter { activity in
            let matchesCategory = criteria.category.isBrowseAggregate || activity.category == criteria.category
            guard matchesCategory, matchesQuickFilters(activity, criteria: criteria) else { return false }
            guard !query.isEmpty else { return true }
            return matchesSearch(activity, query: query)
        }
    }

    private func matchesSearch(_ activity: Activity, query: String) -> Bool {
        if activity.title.localizedCaseInsensitiveContains(query) { return true }
        if activity.location.localizedCaseInsensitiveContains(query) { return true }
        if activity.hostName.localizedCaseInsensitiveContains(query) { return true }
        if activity.summary.localizedCaseInsensitiveContains(query) { return true }
        if activity.fee.localizedCaseInsensitiveContains(query) { return true }
        return activity.tags.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    private func matchesQuickFilters(_ activity: Activity, criteria: ActivityBrowseCriteria) -> Bool {
        let calendar = Calendar.current

        if let dayFilter = criteria.dayFilter {
            guard calendar.isDate(activity.date, inSameDayAs: dayFilter) else { return false }
        }

        guard !criteria.quickFilters.isEmpty else { return true }

        return criteria.quickFilters.allSatisfy { filter in
            switch filter {
            case .weekend:
                criteria.dayFilter == nil
                    && isUpcomingWeekend(activity.date, calendar: calendar, now: criteria.now)
            case .today:
                criteria.dayFilter == nil && calendar.isDateInToday(activity.date) && activity.date >= criteria.now
            case .tomorrow:
                criteria.dayFilter == nil && calendar.isDateInTomorrow(activity.date)
            case .nearby:
                activity.distanceKM <= criteria.nearbyRadiusKM && activity.date >= criteria.now
            case .free:
                activity.isFree
            case .available:
                activity.hasAvailableSpots && activity.date >= criteria.now
            }
        }
    }

    private func isUpcomingWeekend(_ date: Date, calendar: Calendar, now: Date) -> Bool {
        guard date >= now else { return false }
        let weekday = calendar.component(.weekday, from: date)
        // 1 = Sunday, 7 = Saturday
        guard weekday == 1 || weekday == 7 else { return false }
        guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
            return false
        }
        guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
            return false
        }
        return date < endOfWeek
    }
}
