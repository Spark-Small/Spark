//
//  ActivitiesModel+Hosting.swift
//  坐标系
//

import Foundation
import Observation
import CoordinateModels

extension ActivitiesModel {
    @discardableResult
    func publish(
        title: String,
        category: ActivityCategory,
        location: String,
        date: Date,
        capacity: Int,
        fee: String,
        summary: String,
        tags: [String],
        localCoverName: String?,
        distanceKM: Double = 1.5,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> Activity.ID? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedLocation.isEmpty, !trimmedSummary.isEmpty else { return nil }
        guard !category.isBrowseAggregate else { return nil }

        var resolvedDistance = distanceKM
        if let latitude, let longitude,
           let km = locationService.distanceKM(to: latitude, longitude: longitude) {
            resolvedDistance = km
        }

        let id = UUID()
        activities.insert(
            Activity(
                id: id,
                title: trimmedTitle,
                category: category,
                location: trimmedLocation,
                date: date,
                capacity: max(capacity, 2),
                joined: 1,
                hostName: currentUserName,
                summary: trimmedSummary,
                fee: fee.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "免费" : fee,
                tags: tags,
                distanceKM: resolvedDistance,
                localCoverName: localCoverName,
                participantNames: [currentUserName],
                latitude: latitude,
                longitude: longitude
            ),
            at: 0
        )
        joinedIDs.insert(id)
        isComposing = false
        editingActivityID = nil
        publishSuccessActivityID = id
        NotificationService.scheduleActivityReminder(activityID: id, title: trimmedTitle, at: date)
        persist()
        return id
    }

    func beginEdit(_ id: Activity.ID) {
        editingActivityID = id
        isComposing = true
    }

    func update(
        id: Activity.ID,
        title: String,
        category: ActivityCategory,
        location: String,
        date: Date,
        capacity: Int,
        fee: String,
        summary: String,
        tags: [String],
        localCoverName: String?,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return }
        guard activities[index].hostName == currentUserName else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedLocation.isEmpty, !trimmedSummary.isEmpty else { return }
        guard !category.isBrowseAggregate else { return }

        let joinedCount = activities[index].joined
        activities[index].title = trimmedTitle
        activities[index].category = category
        activities[index].location = trimmedLocation
        activities[index].date = date
        activities[index].capacity = max(capacity, max(joinedCount, 2))
        activities[index].summary = trimmedSummary
        activities[index].fee = fee.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "免费" : fee
        activities[index].tags = tags
        if let localCoverName {
            activities[index].localCoverName = localCoverName
        }
        if latitude != nil { activities[index].latitude = latitude }
        if longitude != nil { activities[index].longitude = longitude }
        if let lat = activities[index].latitude,
           let lon = activities[index].longitude,
           let km = locationService.distanceKM(to: lat, longitude: lon) {
            activities[index].distanceKM = km
        }
        isComposing = false
        editingActivityID = nil
        if joinedIDs.contains(id) {
            NotificationService.scheduleActivityReminder(activityID: id, title: trimmedTitle, at: date)
        }
        flash(ActivityFeedbackCopy.activityUpdated)
        persist()
    }

    func cancelActivity(_ id: Activity.ID) {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return }
        guard activities[index].hostName == currentUserName else { return }
        if let cover = activities[index].localCoverName {
            LocalMediaLibrary.delete(named: cover)
        }
        ActivityDetailContentStore.delete(for: id)
        joinedIDs.remove(id)
        favoriteIDs.remove(id)
        waitlistIDs.remove(id)
        NotificationService.cancelActivityReminder(activityID: id)
        activities.remove(at: index)
        if joinSuccessActivityID == id {
            joinSuccessActivityID = nil
        }
        if publishSuccessActivityID == id {
            publishSuccessActivityID = nil
        }
        flash(ActivityFeedbackCopy.activityCancelled)
        persist()
    }

    func updateCapacity(_ id: Activity.ID, capacity: Int) {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return }
        guard activities[index].hostName == currentUserName else { return }
        let floor = max(activities[index].joined, 2)
        let next = max(capacity, floor)
        guard activities[index].capacity != next else { return }
        let wasFull = activities[index].isFull
        activities[index].capacity = next
        flash(ActivityFeedbackCopy.capacityUpdated(to: next))
        persist()
        if wasFull, !activities[index].isFull {
            processWaitlistSpotAvailability(for: id)
        }
    }

    func reschedule(_ id: Activity.ID, to date: Date, notifyNote: String?) {
        guard let index = activities.firstIndex(where: { $0.id == id }) else { return }
        guard activities[index].hostName == currentUserName else { return }
        guard date > .now else {
            flash(ActivityFeedbackCopy.scheduleNeedsFuture)
            return
        }
        activities[index].date = date
        if joinedIDs.contains(id) {
            NotificationService.scheduleActivityReminder(
                activityID: id,
                title: activities[index].title,
                at: date
            )
        }
        if let notifyNote = notifyNote?.trimmingCharacters(in: .whitespacesAndNewlines),
           !notifyNote.isEmpty {
            var override = ActivityDetailContentStore.override(for: id) ?? ActivityDetailContentOverride()
            let line = "【改期通知】\(Formatters.activityEventTime(from: date)) · \(notifyNote)"
            if let existing = override.hostNote, !existing.isEmpty {
                override.hostNote = existing + "\n" + line
            } else {
                override.hostNote = line
            }
            ActivityDetailContentStore.save(override, for: id)
        }
        flash(ActivityFeedbackCopy.scheduleUpdated)
        persist()
    }
}
