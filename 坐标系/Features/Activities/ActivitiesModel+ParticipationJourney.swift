//
//  ActivitiesModel+ParticipationJourney.swift
//  坐标系
//
//  活动参与旅程进度：到场、入群、反馈、复盘等持久状态。
//

import Foundation
import CoordinateModels

extension ActivitiesModel {
    func participationRecord(for activityID: Activity.ID) -> ActivityParticipationProgress? {
        participationProgress.first { $0.activityID == activityID }
    }

    func ensureParticipationProgress(for activityID: Activity.ID) {
        guard isJoined(activityID),
              !participationProgress.contains(where: { $0.activityID == activityID })
        else { return }
        participationProgress.append(ActivityParticipationProgress(activityID: activityID))
        persist()
    }

    func removeParticipationProgress(for activityID: Activity.ID) {
        let before = participationProgress.count
        participationProgress.removeAll { $0.activityID == activityID }
        guard participationProgress.count != before else { return }
        persist()
    }

    func markActivityArrived(_ activityID: Activity.ID, at date: Date = .now) {
        mutateParticipation(for: activityID) {
            $0.markedArrived = true
            if $0.arrivedAt == nil {
                $0.arrivedAt = date
            }
        }
    }

    func markActivityGroupOpened(_ activityID: Activity.ID) {
        mutateParticipation(for: activityID) { $0.openedActivityGroup = true }
    }

    func submitActivityFeedback(_ activityID: Activity.ID, highlight: String? = nil) {
        mutateParticipation(for: activityID) {
            $0.feedbackSubmitted = true
            $0.feedbackSkipped = false
            if let highlight, !highlight.isEmpty {
                $0.feedbackHighlight = highlight
            }
        }
        if let highlight, !highlight.isEmpty {
            recordFeedbackTag(highlight, for: activityID)
        }
    }

    func recordFeedbackTag(_ tag: String, for activityID: Activity.ID) {
        let key = activityID.uuidString
        var tags = feedbackTagCounts[key, default: [:]]
        tags[tag, default: 0] += 1
        feedbackTagCounts[key] = tags
        persist()
    }

    func feedbackTagSummary(for activityID: Activity.ID, limit: Int = 3) -> [(tag: String, count: Int)] {
        let key = activityID.uuidString
        guard let tags = feedbackTagCounts[key], !tags.isEmpty else { return [] }
        return tags
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(limit)
            .map { (tag: $0.key, count: $0.value) }
    }

    func skipActivityFeedback(_ activityID: Activity.ID) {
        mutateParticipation(for: activityID) {
            $0.feedbackSkipped = true
            $0.feedbackSubmitted = false
        }
    }

    func skipActivityRecap(_ activityID: Activity.ID) {
        mutateParticipation(for: activityID) {
            $0.recapSkipped = true
            $0.recapPublished = false
        }
        flashLight("已跳过复盘")
    }

    func markActivityRecapPublished(_ activityID: Activity.ID) {
        mutateParticipation(for: activityID) {
            $0.recapPublished = true
            $0.recapSkipped = false
        }
        flashLight(ActivityFeedbackCopy.recapPublished)
    }

    private func mutateParticipation(
        for activityID: Activity.ID,
        _ transform: (inout ActivityParticipationProgress) -> Void
    ) {
        if let index = participationProgress.firstIndex(where: { $0.activityID == activityID }) {
            transform(&participationProgress[index])
        } else {
            var record = ActivityParticipationProgress(activityID: activityID)
            transform(&record)
            participationProgress.append(record)
        }
        persist()
    }
}
