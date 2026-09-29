//
//  ActivitiesModel+DemoJourney.swift
//  坐标系
//
//  DEBUG only：「剧本杀：情感本」静默写入参加态。Release 无此路径。
//

#if DEBUG
import CoordinateDomain
import Foundation
import CoordinateModels

extension ActivitiesModel {
  func ensureDemoScriptMurderJourneyJoined() {
    let activityID = SampleData.demoJourneyActivityID
    guard !joinedIDs.contains(activityID) else { return }
    guard activity(id: activityID) != nil else { return }

    if case .success = participation.join.execute(
      activityID: activityID,
      activities: &activities,
      joinedIDs: &joinedIDs,
      waitlistIDs: &waitlistIDs,
      waitlistSpotNotifiedIDs: &waitlistSpotNotifiedIDs,
      currentUserName: currentUserName
    ) {
      ensureParticipationProgress(for: activityID)
      if let activity = activity(id: activityID) {
        engagementStore.record(.joined, for: activity)
        NotificationService.scheduleActivityReminder(
          activityID: activityID,
          title: activity.title,
          at: activity.date
        )
      }
      persist()
    }
  }
}
#endif
