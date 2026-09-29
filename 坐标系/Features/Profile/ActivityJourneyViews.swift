//
//  ActivityJourneyViews.swift
//  坐标系
//
//  我的行程：活动凭证（含票面下沿进度）+ 下一步。
//

import SwiftUI
import CoordinateDomain
import CoordinateModels

// MARK: - Stack

struct ActivityJourneyStack: View {
    let activity: Activity
    let phase: ActivityParticipationPhase?
    let progress: ActivityParticipationProgress?
    var voided: Bool = false
    var isOnCalendar: Bool = false
    var userID: UUID
    var participantName: String
    var participantUIDDisplay: String
    var barcodeMessage: String
    var coParticipantNames: [String] = []
    let onUtilityAction: (ActivityJourneyUtilityAction) -> Void
    let onPrimaryAction: (ActivityJourneyPrimaryAction) -> Void
    var onGreetParticipant: ((String) -> Void)? = nil

    private var nextStep: ActivityJourneyNextStepContent {
        ActivityJourneyPresentation.nextStepContent(
            for: activity,
            phase: phase,
            progress: progress,
            voided: voided,
            isOnCalendar: isOnCalendar,
            showsNavigate: showsNavigate
        )
    }

    private var showsNavigate: Bool {
        activity.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: PlatformMetrics.sectionSpacing) {
                ActivityJourneyCredentialPanel(
                    activity: activity,
                    phase: phase,
                    progress: progress,
                    voided: voided,
                    isOnCalendar: isOnCalendar,
                    focusStep: nextStep.focusStep,
                    userID: userID,
                    participantName: participantName,
                    participantUIDDisplay: participantUIDDisplay,
                    barcodeMessage: barcodeMessage
                )

                DiscoverBrowseSection {
                    DiscoverSectionTitleRow(
                        title: ActivityJourneyCopy.nextStepTitle,
                        showsHorizontalInset: false
                    )
                } content: {
                    ActivityJourneyNextStepSection(
                        content: nextStep,
                        onUtilityAction: onUtilityAction,
                        onPrimaryAction: onPrimaryAction
                    )
                }

                if activity.isLifecycleEnded, !coParticipantNames.isEmpty, let onGreetParticipant {
                    DiscoverBrowseSection {
                        DiscoverSectionTitleRow(
                            title: ActivityJourneyCopy.coParticipantsTitle,
                            subtitle: ActivityJourneyCopy.coParticipantsSubtitle,
                            showsHorizontalInset: false
                        )
                    } content: {
                        ActivityJourneyCoParticipantsSection(
                            names: coParticipantNames,
                            onGreet: onGreetParticipant
                        )
                    }
                }
            }
            .frame(maxWidth: PlatformMetrics.journeyContentMaxWidth)
            .frame(maxWidth: .infinity)
            .discoverBrowsePageColumn()
            .discoverBrowseContentInset()
        }
        .discoverBrowseScrollChrome()
    }
}

// MARK: - Credential

struct ActivityJourneyCredentialPanel: View {
    let activity: Activity
    let phase: ActivityParticipationPhase?
    let progress: ActivityParticipationProgress?
    var voided: Bool = false
    var isOnCalendar: Bool = false
    var focusStep: ActivityJourneyStep?
    let userID: UUID
    let participantName: String
    let participantUIDDisplay: String
    var barcodeMessage: String

    private var credentialModel: ActivityJourneyCredentialModel {
        ActivityJourneyCredentialPresentation.model(
            for: activity,
            phase: phase,
            voided: voided,
            userID: userID,
            participantName: participantName,
            participantUIDDisplay: participantUIDDisplay,
            barcodeMessage: barcodeMessage
        )
    }

    private var progressRows: [ActivityJourneyTimelineRow] {
        ActivityJourneyPresentation.timeline(
            phase: phase,
            progress: progress,
            isOnCalendar: isOnCalendar,
            activityID: activity.id,
            focusStep: focusStep
        )
    }

    private var showsProgressStrip: Bool {
        !voided && credentialModel.presentation == .fulfillment
    }

    var body: some View {
        ActivityJourneyCredentialFace(
            model: credentialModel,
            progressRows: showsProgressStrip ? progressRows : []
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(passAccessibilityLabel)
    }

    private var passAccessibilityLabel: String {
        if voided {
            return "\(activity.title)，\(ActivityJourneyCopy.voided)"
        }
        if showsProgressStrip {
            return "\(credentialModel.accessibilitySummary)，\(ActivityJourneyCopy.progressAccessibility(rows: progressRows))"
        }
        return credentialModel.accessibilitySummary
    }
}

// MARK: - Next step

private struct ActivityJourneyNextStepSection: View {
    let content: ActivityJourneyNextStepContent
    let onUtilityAction: (ActivityJourneyUtilityAction) -> Void
    let onPrimaryAction: (ActivityJourneyPrimaryAction) -> Void

    var body: some View {
        VStack(spacing: PlatformMetrics.sectionHeaderSpacing) {
            ActivityJourneyPrimaryBannerButton(face: content.banner.face) {
                onPrimaryAction(content.banner.primary)
            }

            if !content.interactiveUtilities.isEmpty {
                utilityGrid
            }

            if !content.statusRows.isEmpty {
                VStack(spacing: PlatformMetrics.cardInfoSpacing) {
                    ForEach(content.statusRows) { row in
                        ActivityJourneyUtilityStatusRowView(row: row)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var utilityGrid: some View {
        let cards = content.interactiveUtilities
        if cards.count == 1 {
            ActivityJourneyGlassCardButton(face: cards[0].face) {
                onUtilityAction(cards[0].action)
            }
        } else {
            HStack(alignment: .top, spacing: PlatformMetrics.detailBottomBarSpacing) {
                ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                    ActivityJourneyGlassCardButton(face: card.face) {
                        onUtilityAction(card.action)
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
    }
}

private struct ActivityJourneyPrimaryBannerButton: View {
    let face: ActivityJourneyGlassCardFace
    let action: () -> Void

    var body: some View {
        ActivityJourneyGlassCardButton(face: face, action: action)
            .accessibilityAddTraits(.isButton)
    }
}

private struct ActivityJourneyUtilityStatusRowView: View {
    let row: ActivityJourneyUtilityStatusRow

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: PlatformMetrics.cardInfoSpacing) {
            Image(systemName: row.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(row.isComplete ? .green : .secondary)
                .symbolRenderingMode(row.isComplete ? .monochrome : .hierarchical)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize))
                Text(row.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(PlatformMetrics.formRowVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .platformThinMaterialBackground(in: PlatformMetrics.cardShape)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.title)，\(row.subtitle)")
    }
}

private struct ActivityJourneyGlassCardButton: View {
    let face: ActivityJourneyGlassCardFace
    var isEnabled: Bool = true
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        PlatformGlassLabelCardButton(
            title: face.title,
            subtitle: face.subtitle,
            systemImage: face.systemImage,
            symbolChrome: face.isCheckedIn ? .status(.green) : .multicolor,
            titleLineLimit: DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize),
            subtitleLineLimit: DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize),
            action: action
        )
        .disabled(!isEnabled)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct ActivityJourneyCoParticipantsSection: View {
    let names: [String]
    let onGreet: (String) -> Void

    var body: some View {
        VStack(spacing: PlatformMetrics.cardInfoSpacing) {
            ForEach(names, id: \.self) { name in
                HStack(spacing: PlatformMetrics.cardInfoSpacing) {
                    PlatformListAvatarView(name: name)
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button(ActivityJourneyCopy.greetParticipant(name)) {
                        onGreet(name)
                    }
                    .font(.footnote.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(PlatformMetrics.formRowVerticalPadding)
                .platformThinMaterialBackground(in: PlatformMetrics.cardShape)
            }
        }
    }
}
