//
//  ActivityJourneyCredentialPresentation.swift
//  坐标系
//
//  Activity → ActivityJourneyCredentialModel（行程页 + 分享单源）。
//

import Foundation
import CoordinateModels

@MainActor
enum ActivityJourneyCredentialPresentation {
    static func presentationMode(
        phase: ActivityParticipationPhase?,
        voided: Bool
    ) -> ActivityJourneyCredentialPresentationMode {
        if voided { return .voided }
        switch phase {
        case .awaitingFeedback, .recapEligible, .closed:
            return .memento
        default:
            return .fulfillment
        }
    }

    static func mementoHeadline(
        for activity: Activity,
        phase: ActivityParticipationPhase?,
        voided: Bool
    ) -> String? {
        guard !voided else { return nil }
        let status = ActivityJourneyPresentation.passStatus(
            for: activity,
            phase: phase,
            voided: false
        )
        switch phase {
        case .awaitingFeedback, .recapEligible, .closed:
            return status.title
        default:
            return nil
        }
    }

    static func model(
        for activity: Activity,
        phase: ActivityParticipationPhase?,
        voided: Bool,
        userID: UUID,
        participantName: String,
        participantUIDDisplay: String,
        barcodeMessage: String
    ) -> ActivityJourneyCredentialModel {
        let presentation = presentationMode(phase: phase, voided: voided)
        let passKind = ActivityPassFieldBuilder.kind(for: activity.category)
        let art = CredentialArtCatalog.resolve(kind: passKind, presentation: presentation)

        let face = PassFacePresentation.activityJourneyFaceModel(
            for: activity,
            voided: voided,
            userID: userID,
            participantName: participantName,
            participantUIDDisplay: participantUIDDisplay,
            barcodeMessage: barcodeMessage
        )

        return ActivityJourneyCredentialModel(
            face: face,
            presentation: presentation,
            artScene: art.scene,
            artTheme: art.theme,
            mementoHeadline: mementoHeadline(for: activity, phase: phase, voided: voided)
        )
    }

    static func shareCaption(for activity: Activity) -> String {
        let schedule = Formatters.activityEventTime(from: activity.date)
        let location = activity.location.trimmingCharacters(in: .whitespacesAndNewlines)
        var lines = [
            "我在坐标系参加了「\(activity.title)」",
            schedule
        ]
        if !location.isEmpty {
            lines.append(location)
        }
        return lines.joined(separator: "\n")
    }

    static func canShareMemento(voided: Bool, participatesInJourney: Bool) -> Bool {
        !voided && participatesInJourney
    }

    /// 分享纪念图：始终用纪念版式；插画在活动结束后切换为完成态。
    static func shareModel(
        for activity: Activity,
        phase: ActivityParticipationPhase?,
        voided: Bool,
        userID: UUID,
        participantName: String,
        participantUIDDisplay: String,
        barcodeMessage: String
    ) -> ActivityJourneyCredentialModel {
        let base = model(
            for: activity,
            phase: phase,
            voided: voided,
            userID: userID,
            participantName: participantName,
            participantUIDDisplay: participantUIDDisplay,
            barcodeMessage: barcodeMessage
        )
        let passKind = ActivityPassFieldBuilder.kind(for: activity.category)
        let isPostEvent = base.presentation == .memento
        let art = CredentialArtCatalog.resolveForShare(
            kind: passKind,
            isPostEvent: isPostEvent
        )
        let headline = ActivityJourneyPresentation.passStatus(
            for: activity,
            phase: phase,
            voided: false
        ).title
        return ActivityJourneyCredentialModel(
            face: base.face,
            presentation: .memento,
            artScene: art.scene,
            artTheme: art.theme,
            mementoHeadline: headline
        )
    }
}
