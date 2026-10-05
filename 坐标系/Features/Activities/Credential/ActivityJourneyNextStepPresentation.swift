//
//  ActivityJourneyNextStepPresentation.swift
//  坐标系
//
//  行程「下一步」：赴约四件套（约陪玩可选）+ 类目扩展格 + 结束后反馈 / 复盘。
//

import Foundation
import CoordinateDomain
import CoordinateModels

extension ActivityJourneyPresentation {
    /// 下一步：赴约四件套（2 列）+ 合适类目扩展；反馈 / 复盘走 postBanner。
    @MainActor
    static func nextStepContent(
        for activity: Activity,
        phase: ActivityParticipationPhase?,
        progress: ActivityParticipationProgress?,
        voided: Bool,
        isOnCalendar: Bool,
        showsNavigate: Bool
    ) -> ActivityJourneyNextStepContent {
        if voided {
            return ActivityJourneyNextStepContent(
                focusStep: .registered,
                kitItems: [],
                postBanner: ActivityJourneyBannerContent(
                    face: ActivityJourneyGlassCardFace(
                        title: ActivityJourneyCopy.detailBannerTitle,
                        subtitle: ActivityJourneyCopy.detail,
                        systemImage: "calendar"
                    ),
                    primary: .openDetail
                )
            )
        }

        let progress = progress ?? ActivityParticipationProgress(activityID: activity.id)
        let focusStep = focusTimelineStep(
            phase: phase,
            progress: progress,
            isOnCalendar: isOnCalendar
        )

        if usesDepartureKit(focusStep: focusStep) {
            return ActivityJourneyNextStepContent(
                focusStep: focusStep,
                kitItems: departureKit(
                    activity: activity,
                    phase: phase,
                    progress: progress,
                    showsNavigate: showsNavigate
                ),
                postBanner: nil
            )
        }

        return ActivityJourneyNextStepContent(
            focusStep: focusStep,
            kitItems: [],
            postBanner: postActivityBanner(for: focusStep)
        )
    }

    static func usesDepartureKit(focusStep: ActivityJourneyStep) -> Bool {
        switch focusStep {
        case .registered, .joinedGroup, .dayOfReady, .arrived:
            return true
        case .feedback, .recap:
            return false
        }
    }

    static func canCheckIn(
        phase: ActivityParticipationPhase?,
        markedArrived: Bool,
        voided: Bool
    ) -> Bool {
        guard !voided, !markedArrived else { return false }
        switch phase {
        case .dayOf, .inProgress:
            return true
        default:
            return false
        }
    }

    /// 约陪玩 → 进入群聊 → 导航前往 → 到场签到；合适类目再追加装备 / 注意事项。
    @MainActor
    private static func departureKit(
        activity: Activity,
        phase: ActivityParticipationPhase?,
        progress: ActivityParticipationProgress,
        showsNavigate: Bool
    ) -> [ActivityJourneyKitItem] {
        let location = activity.location.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasLocation = showsNavigate && !location.isEmpty

        let checkInReady = canCheckIn(phase: phase, markedArrived: false, voided: false)
        let checkInComplete = progress.markedArrived
        let checkInSubtitle: String
        if checkInComplete {
            checkInSubtitle = checkedInSubtitle(arrivedAt: progress.arrivedAt)
        } else if checkInReady {
            checkInSubtitle = ActivityJourneyCopy.checkInPrompt
        } else {
            checkInSubtitle = ActivityJourneyCopy.checkInEarly
        }

        var items: [ActivityJourneyKitItem] = [
            ActivityJourneyKitItem(
                action: .bookCompanion,
                face: ActivityJourneyGlassCardFace(
                    title: ActivityJourneyCopy.bookCompanionTitle,
                    subtitle: ActivityJourneyCopy.bookCompanionSubtitle,
                    systemImage: "person.2.fill"
                ),
                isEnabled: true
            ),
            ActivityJourneyKitItem(
                action: .openGroup,
                face: ActivityJourneyGlassCardFace(
                    title: ActivityJourneyCopy.openGroupChat,
                    subtitle: ActivityJourneyCopy.groupChatSubtitle,
                    systemImage: "bubble.left.and.bubble.right.fill"
                ),
                isEnabled: true
            ),
            ActivityJourneyKitItem(
                action: .navigate,
                face: ActivityJourneyGlassCardFace(
                    title: ActivityJourneyCopy.navigate,
                    subtitle: hasLocation ? location : ActivityJourneyCopy.navigateUnavailable,
                    systemImage: "map.fill"
                ),
                isEnabled: hasLocation
            ),
            ActivityJourneyKitItem(
                action: .checkIn,
                face: ActivityJourneyGlassCardFace(
                    title: checkInComplete
                        ? ActivityJourneyCopy.checkedInTitle
                        : ActivityJourneyCopy.onSiteCheckIn,
                    subtitle: checkInSubtitle,
                    systemImage: checkInComplete ? "checkmark.circle.fill" : "figure.wave",
                    isCheckedIn: checkInComplete
                ),
                isEnabled: !checkInComplete,
                isComplete: checkInComplete
            )
        ]
        items.append(contentsOf: categoryExtensionItems(for: activity))
        return items
    }

    /// 运动户外 / 城市探索 / 手工 / 娱乐：有蓝图内容才出扩展格（最多 +2）。
    @MainActor
    private static func categoryExtensionItems(for activity: Activity) -> [ActivityJourneyKitItem] {
        guard supportsCategoryExtensions(activity.category) else { return [] }
        let blueprint = ActivityDetailBlueprint.make(for: activity)
        var extra: [ActivityJourneyKitItem] = []
        if !blueprint.gear.isEmpty {
            extra.append(
                ActivityJourneyKitItem(
                    action: .openGearPrep,
                    face: ActivityJourneyGlassCardFace(
                        title: ActivityJourneyCopy.gearPrepTitle,
                        subtitle: ActivityJourneyCopy.gearPrepSubtitle,
                        systemImage: "backpack.fill"
                    ),
                    isEnabled: true
                )
            )
        }
        if !blueprint.prepNotes.isEmpty || !blueprint.registrationNotes.isEmpty {
            extra.append(
                ActivityJourneyKitItem(
                    action: .openNotices,
                    face: ActivityJourneyGlassCardFace(
                        title: ActivityJourneyCopy.noticesTitle,
                        subtitle: ActivityJourneyCopy.noticesSubtitle,
                        systemImage: "exclamationmark.triangle.fill"
                    ),
                    isEnabled: true
                )
            )
        }
        return extra
    }

    private static func supportsCategoryExtensions(_ category: ActivityCategory) -> Bool {
        switch category {
        case .outdoorSports, .cityExplore, .handmade, .entertainment:
            return true
        case .all, .forYou, .interestSocial, .food, .learning:
            return false
        }
    }

    private static func postActivityBanner(
        for focusStep: ActivityJourneyStep
    ) -> ActivityJourneyBannerContent {
        switch focusStep {
        case .feedback:
            return ActivityJourneyBannerContent(
                face: ActivityJourneyGlassCardFace(
                    title: ActivityJourneyCopy.shareFeedback,
                    subtitle: ActivityJourneyCopy.feedbackPrompt,
                    systemImage: "hand.thumbsup"
                ),
                primary: .shareFeedback
            )
        case .recap:
            return ActivityJourneyBannerContent(
                face: ActivityJourneyGlassCardFace(
                    title: ActivityJourneyCopy.writeRecap,
                    subtitle: ActivityJourneyCopy.recapBannerSubtitle,
                    systemImage: "square.and.pencil"
                ),
                primary: .writeRecap
            )
        case .registered, .joinedGroup, .dayOfReady, .arrived:
            return ActivityJourneyBannerContent(
                face: ActivityJourneyGlassCardFace(
                    title: ActivityJourneyCopy.detailBannerTitle,
                    subtitle: ActivityJourneyCopy.detail,
                    systemImage: "calendar"
                ),
                primary: .openDetail
            )
        }
    }

    private static func checkedInSubtitle(arrivedAt: Date?) -> String {
        guard let arrivedAt else { return ActivityJourneyCopy.checkedInTitle }
        return "\(ActivityJourneyCopy.checkedInAtPrefix) \(Formatters.shortTime.string(from: arrivedAt))"
    }
}
