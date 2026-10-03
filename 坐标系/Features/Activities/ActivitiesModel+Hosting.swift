//
//  ActivitiesModel+Hosting.swift
//  坐标系
//
//  发起人写路径：Domain Hosting UC + 本机副作用。
//

import CoordinateDomain
import Foundation
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
        var resolvedDistance = distanceKM
        if let latitude, let longitude,
           let km = locationService.distanceKM(to: latitude, longitude: longitude) {
            resolvedDistance = km
        }

        let draft = PublishActivityDraft(
            title: title,
            category: category,
            location: location,
            date: date,
            capacity: capacity,
            fee: fee,
            freeFeeLabel: ActivityCardStatus.free,
            summary: summary,
            tags: tags,
            localCoverName: localCoverName,
            distanceKM: resolvedDistance,
            latitude: latitude,
            longitude: longitude,
            hostName: currentUserName,
            hostUserID: currentUserID
        )

        switch hosting.publish.execute(
            draft: draft,
            activities: &activities,
            joinedIDs: &joinedIDs
        ) {
        case .success(let id):
            presentation.endCompose()
            presentation.publishSuccessActivityID = id
            NotificationService.scheduleActivityReminder(
                activityID: id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                at: date
            )
            invalidateRecommendationShelvesCache()
            persist()
            return id
        case .failure:
            return nil
        }
    }

    func beginEdit(_ id: Activity.ID) {
        presentation.beginCompose(editing: id)
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
        var distanceKM: Double?
        if let latitude, let longitude,
           let km = locationService.distanceKM(to: latitude, longitude: longitude) {
            distanceKM = km
        } else if let existing = activity(id: id),
                  let lat = latitude ?? existing.latitude,
                  let lon = longitude ?? existing.longitude,
                  let km = locationService.distanceKM(to: lat, longitude: lon) {
            distanceKM = km
        }

        let draft = UpdateActivityDraft(
            id: id,
            title: title,
            category: category,
            location: location,
            date: date,
            capacity: capacity,
            fee: fee,
            freeFeeLabel: ActivityCardStatus.free,
            summary: summary,
            tags: tags,
            localCoverName: localCoverName,
            latitude: latitude,
            longitude: longitude,
            distanceKM: distanceKM
        )

        switch hosting.update.execute(
            draft: draft,
            activities: &activities,
            hostName: currentUserName,
            hostUserID: currentUserID
        ) {
        case .success:
            presentation.endCompose()
            if joinedIDs.contains(id) {
                NotificationService.scheduleActivityReminder(
                    activityID: id,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    at: date
                )
            }
            invalidateRecommendationShelvesCache()
            flash(ActivityFeedbackCopy.activityUpdated)
            persist()
        case .failure:
            break
        }
    }

    func cancelActivity(_ id: Activity.ID) {
        switch hosting.cancel.execute(
            activityID: id,
            activities: &activities,
            joinedIDs: &joinedIDs,
            favoriteIDs: &favoriteIDs,
            waitlistIDs: &waitlistIDs,
            hostName: currentUserName,
            hostUserID: currentUserID
        ) {
        case .success(let result):
            if let cover = result.coverName {
                LocalMediaLibrary.delete(named: cover)
            }
            ActivityDetailContentStore.delete(for: id)
            NotificationService.cancelActivityReminder(activityID: id)
            if presentation.joinSuccessActivityID == id {
                presentation.joinSuccessActivityID = nil
            }
            if presentation.publishSuccessActivityID == id {
                presentation.publishSuccessActivityID = nil
            }
            invalidateRecommendationShelvesCache()
            flash(ActivityFeedbackCopy.activityCancelled)
            persist()
        case .failure:
            break
        }
    }

    func updateCapacity(_ id: Activity.ID, capacity: Int) {
        switch hosting.updateCapacity.execute(
            activityID: id,
            capacity: capacity,
            activities: &activities,
            hostName: currentUserName,
            hostUserID: currentUserID
        ) {
        case .success(let result):
            flash(ActivityFeedbackCopy.capacityUpdated(to: result.capacity))
            persist()
            if result.openedSpotFromFull {
                processWaitlistSpotAvailability(for: id)
            }
        case .failure(.unchanged), .failure(.activityNotFound), .failure(.notHost):
            break
        }
    }

    func reschedule(_ id: Activity.ID, to date: Date, notifyNote: String?) {
        switch hosting.reschedule.execute(
            activityID: id,
            date: date,
            activities: &activities,
            hostName: currentUserName,
            hostUserID: currentUserID
        ) {
        case .success:
            if joinedIDs.contains(id), let title = activity(id: id)?.title {
                NotificationService.scheduleActivityReminder(
                    activityID: id,
                    title: title,
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
        case .failure(.dateNotInFuture):
            flash(ActivityFeedbackCopy.scheduleNeedsFuture)
        case .failure:
            break
        }
    }
}
