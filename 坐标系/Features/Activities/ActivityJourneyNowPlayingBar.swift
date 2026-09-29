//
//  ActivityJourneyNowPlayingBar.swift
//  坐标系
//
//  活动 Tab `tabViewBottomAccessory`：我的行程队列 + 下一场摘要字段。
//

import SwiftUI
import CoordinateDomain
import CoordinateModels

enum ActivityJourneyNowPlayingCopy {
    static let idleTitle = "未在播放"
    static let idleSubtitle = "参加后可在此继续"
    static let navigateTitle = "导航"
    static let journeyTitle = "行程"
    static let departTitle = "出行"
    static let navigateAccessibility = ActivityJourneyCopy.navigate
    static let journeyAccessibility = ActivityJourneyCopy.openAction
    static let departAccessibility = "查看待出行行程"

    static func trailingTitle(for phase: ActivityNextUpPresentation.Phase) -> String {
        switch phase {
        case .preparing: departTitle
        case .today, .inProgress: navigateTitle
        case .ended: journeyTitle
        }
    }

    static func trailingAccessibility(for phase: ActivityNextUpPresentation.Phase) -> String {
        switch phase {
        case .preparing: departAccessibility
        case .today, .inProgress: navigateAccessibility
        case .ended: journeyAccessibility
        }
    }
}

@MainActor
enum ActivityJourneyNowPlayingPresentation {
    enum TrailingAction: Equatable {
        case openProfileJourneys
        case openJourney(Activity.ID)
        case navigate(Activity.ID)
    }

    struct Snapshot: Equatable {
        let activity: Activity?
        let title: String
        let subtitle: String?
        let footnote: String?
        let trailingTitle: String
        let trailingAccessibilityLabel: String
        let trailingAction: TrailingAction
        let tapAction: TrailingAction

        var accessibilitySummary: String {
            [title, subtitle, footnote]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "，")
        }
    }

    static func snapshot(
        for activities: ActivitiesModel,
        hasSeenWelcomeGuide: Bool,
        now: Date = .now
    ) -> Snapshot {
        let queue = ActivityNextUpPresentation.playbackQueue(from: activities)
        guard let activity = queue.first else {
            return idleSnapshot
        }

        if hasSeenWelcomeGuide,
           let summary = ActivityNextUpPresentation.summary(
               for: activities,
               hasSeenWelcomeGuide: true,
               now: now
           ),
           summary.activity.id == activity.id {
            return journeySnapshot(for: activity, summary: summary)
        }

        return queuedSnapshot(for: activity)
    }

    private static var idleSnapshot: Snapshot {
        Snapshot(
            activity: nil,
            title: ActivityJourneyNowPlayingCopy.idleTitle,
            subtitle: ActivityJourneyNowPlayingCopy.idleSubtitle,
            footnote: nil,
            trailingTitle: ActivityJourneyNowPlayingCopy.departTitle,
            trailingAccessibilityLabel: ActivityJourneyNowPlayingCopy.departAccessibility,
            trailingAction: .openProfileJourneys,
            tapAction: .openProfileJourneys
        )
    }

    private static func journeySnapshot(
        for activity: Activity,
        summary: ActivityNextUpPresentation.Summary
    ) -> Snapshot {
        let trailingAction: TrailingAction
        let resolvedTrailingTitle: String
        let trailingAccessibilityLabel: String

        switch summary.primaryAction {
        case .navigate:
            trailingAction = .navigate(activity.id)
            resolvedTrailingTitle = ActivityJourneyNowPlayingCopy.navigateTitle
            trailingAccessibilityLabel = ActivityJourneyNowPlayingCopy.navigateAccessibility
        case .openJourney:
            trailingAction = .openJourney(activity.id)
            resolvedTrailingTitle = ActivityJourneyNowPlayingCopy.trailingTitle(for: summary.phase)
            trailingAccessibilityLabel = ActivityJourneyNowPlayingCopy.trailingAccessibility(for: summary.phase)
        }

        return Snapshot(
            activity: activity,
            title: activity.title,
            subtitle: summary.headline,
            footnote: nil,
            trailingTitle: resolvedTrailingTitle,
            trailingAccessibilityLabel: trailingAccessibilityLabel,
            trailingAction: trailingAction,
            tapAction: tapAction(for: summary)
        )
    }

    private static func queuedSnapshot(for activity: Activity) -> Snapshot {
        Snapshot(
            activity: activity,
            title: activity.title,
            subtitle: Formatters.activityEventTime(from: activity.date),
            footnote: trimmedLocation(activity.location),
            trailingTitle: ActivityJourneyNowPlayingCopy.departTitle,
            trailingAccessibilityLabel: ActivityJourneyNowPlayingCopy.journeyAccessibility,
            trailingAction: .openJourney(activity.id),
            tapAction: .openJourney(activity.id)
        )
    }

    private static func tapAction(
        for summary: ActivityNextUpPresentation.Summary
    ) -> TrailingAction {
        switch summary.primaryAction {
        case .navigate:
            return .navigate(summary.activity.id)
        case .openJourney:
            return .openJourney(summary.activity.id)
        }
    }

    private static func trimmedLocation(_ location: String) -> String? {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct ActivityJourneyNowPlayingBar: View {
    let snapshot: ActivityJourneyNowPlayingPresentation.Snapshot
    var onOpenJourney: (Activity) -> Void
    var onNavigate: (Activity) -> Void
    var onOpenProfileJourneys: () -> Void

    var body: some View {
        DiscoverTabNowPlayingAccessory(
            title: snapshot.title,
            subtitle: snapshot.subtitle,
            footnote: snapshot.footnote,
            trailingActionTitle: snapshot.trailingTitle,
            trailingAccessibilityLabel: snapshot.trailingAccessibilityLabel,
            icon: { accessoryIcon },
            onTap: { perform(snapshot.tapAction) },
            onTrailingAction: { perform(snapshot.trailingAction) }
        )
        .accessibilityLabel(snapshot.accessibilitySummary)
        .accessibilityHint(snapshot.trailingAccessibilityLabel)
    }

    @ViewBuilder
    private var accessoryIcon: some View {
        if let activity = snapshot.activity {
            CommunityRemotePhoto(ref: activity.coverPhoto)
                .frame(
                    width: PlatformConversationListRow.imageSide,
                    height: PlatformConversationListRow.imageSide
                )
                .clipShape(PlatformMetrics.mediaShape)
        } else {
            Image(systemName: "music.note")
                .platformListActionSymbolStyle()
                .foregroundStyle(.secondary)
        }
    }

    private func perform(_ action: ActivityJourneyNowPlayingPresentation.TrailingAction) {
        switch action {
        case .openProfileJourneys:
            onOpenProfileJourneys()
        case .openJourney(let id):
            guard let activity = snapshot.activity, activity.id == id else { return }
            onOpenJourney(activity)
        case .navigate(let id):
            guard let activity = snapshot.activity, activity.id == id else { return }
            onNavigate(activity)
        }
    }
}
