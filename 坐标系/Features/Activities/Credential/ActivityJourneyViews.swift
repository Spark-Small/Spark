//
//  ActivityJourneyViews.swift
//  坐标系
//
//  活动行程：凭证 + 下一步双列四件套（约陪玩可选；合适类目扩展装备/须知）/ 结束后反馈。
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
    var commerce: ActivityJourneyCommerceModel? = nil
    let onUtilityAction: (ActivityJourneyUtilityAction) -> Void
    let onPrimaryAction: (ActivityJourneyPrimaryAction) -> Void
    var onGreetParticipant: ((String) -> Void)? = nil
    var onCommerceAction: ((ActivityJourneyCommerceAction) -> Void)? = nil

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

                if let commerce, let onCommerceAction, commerce.order.status != .cancelled {
                    ActivityJourneyCommerceSection(model: commerce, onAction: onCommerceAction)
                }

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

    @Environment(AppModel.self) private var app
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// HIG：常规两列等宽；无障碍字阶改单列，避免挤扁。
    private var kitColumns: [GridItem] {
        let spacing = PlatformMetrics.sectionHeaderSpacing
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: count
        )
    }

    var body: some View {
        VStack(spacing: PlatformMetrics.sectionHeaderSpacing) {
            if !content.kitItems.isEmpty {
                LazyVGrid(
                    columns: kitColumns,
                    alignment: .leading,
                    spacing: PlatformMetrics.sectionHeaderSpacing
                ) {
                    ForEach(content.kitItems) { item in
                        kitCard(item)
                    }
                }
            }

            if let post = content.postBanner {
                ActivityJourneyGlassCardButton(face: post.face) {
                    onPrimaryAction(post.primary)
                }
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    @ViewBuilder
    private func kitCard(_ item: ActivityJourneyKitItem) -> some View {
        ActivityJourneyGlassCardButton(
            face: item.face,
            isEnabled: item.isEnabled
        ) {
            perform(item)
        }
        .accessibilityHint(
            item.action == .bookCompanion
                ? ActivityJourneyCopy.bookCompanionAccessibilityHint
                : ""
        )
    }

    private func perform(_ item: ActivityJourneyKitItem) {
        guard item.isEnabled else { return }
        switch item.action {
        case .bookCompanion:
            app.openPaidCompanionBrowse()
        case .openGroup:
            onPrimaryAction(.openGroup)
        case .navigate:
            onPrimaryAction(.navigate)
        case .checkIn:
            onUtilityAction(.checkIn)
        case .openGearPrep, .openNotices:
            onPrimaryAction(.openDetail)
        }
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
