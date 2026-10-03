//
//  ActivityDetailView+FormSections.swift
//  坐标系
//
//  活动详情 Form 分区 / Hero / 可折叠内容块。
//

import SwiftUI
import CoordinateDomain
import CoordinateModels

extension ActivityDetailView {
    @ViewBuilder
    func detailFormSections(_ live: Activity, blueprint: ActivityDetailBlueprint) -> some View {
        let joined = model.isJoined(live.id)
        let trust = ActivityHostTrust.make(
            hostName: live.hostName,
            liveHostedCount: model.hostedCount(for: live.hostName)
        )
        let paidOrder = ActivityPaymentStore.displayOrder(for: live.id)

        // 标题 + 决策同一 Section：系统行距，避免两张白卡之间再叠一段分区间距
        Section {
            titleBlock(live)

            ActivityDetailDecisionCard(
                activity: live,
                viewerWaitlisted: model.isWaitlisted(live.id),
                canAddCalendarReminder: joined || model.isHost(live),
                hostNote: blueprint.hostNote,
                matchedFriends: ActivityRecommender.matchedFriends(for: live),
                experienceFeedbackTags: live.isLifecycleEnded
                    ? model.feedbackTagSummary(for: live.id)
                    : [],
                onPeople: { showPeopleSheet = true }
            )
        }
        .id(contentRevision)

        if showsWaitlistPromotion(for: live) {
            Section {
                ActivityWaitlistPromotionBanner(activity: live) {
                    presentJoinConfirm(for: live, waitlistPromotion: true)
                }
            } header: {
                Label(ActivityDetailCopy.waitlistPromotionTitle, systemImage: "sparkles")
                    .platformContentSymbolStyle()
            }
        }

        Section {
            ActivityDetailHostTrustRow(
                trust: trust,
                onHost: { showHostProfile = true },
                onChat: { askHost(about: live) }
            )
        } header: {
            Text(ActivityDetailCopy.peopleHostRole)
        }

        ForEach(blueprint.sections) { section in
            Section {
                let authored = ActivityDetailBlueprint.hasHostAuthoredContent(
                    for: section.id,
                    activity: live
                )
                ActivityDetailCollapsibleSection(
                    title: section.title,
                    summary: ActivityDetailCopy.sectionSummary(
                        authored: authored,
                        contentSummary: ActivityDetailBlueprint.sectionSummary(
                            for: section.id,
                            activity: live,
                            blueprint: blueprint
                        )
                    ),
                    isExpanded: expandedBinding(for: section.id)
                ) {
                    VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
                        if !authored {
                            ActivityDetailTemplateAttribution()
                        }
                        sectionBlock(section: section, blueprint: blueprint)
                            .id(section.id)
                    }
                }
            }
        }

        if isHost, !live.isLifecycleEnded {
            Section {
                ActivityDetailHostManageCard(activity: live)
            } header: {
                Text(ActivityDetailCopy.hostManageTitle)
            }
        }

        footerActions(live, joined: joined)

        if let paidOrder, joined || isHost {
            Section {
                ActivityDetailOrderBanner(order: paidOrder) { showOrders = true }
            }
            .id(ordersRevision)
        }

        if revealsSecondaryContent {
            ActivityDetailCommentsPreviewSection(
                activityID: live.id,
                hostName: live.hostName,
                onOpenComments: { showCommentsSheet = true }
            )
            .id(commentsRevision)

            if let circle = buddies.relatedCircle(for: live) {
                Section {
                    ActivityDetailRelatedCircleRow(circle: circle)
                } header: {
                    Text(ActivityDetailCopy.relatedCircleTitle)
                }
            }

            let related = ActivityRelatedRecommender.related(to: live, from: model.activities)
            if !related.isEmpty {
                Section {
                    DetailRelatedActivitiesRail(activities: related)
                } header: {
                    Text(ActivityDetailCopy.relatedTitle)
                }
            }
        }
    }

    func expandedBinding(for sectionID: ActivityDetailSectionID) -> Binding<Bool> {
        Binding(
            get: { expandedDetailSections.contains(sectionID) },
            set: { isExpanded in
                if isExpanded {
                    expandedDetailSections.insert(sectionID)
                } else {
                    expandedDetailSections.remove(sectionID)
                }
            }
        )
    }

    @ViewBuilder
    func footerActions(_ live: Activity, joined: Bool) -> some View {
        let showHostEdit = isHost
        let showRecap = joined && live.isLifecycleEnded
        let progress = model.participationRecord(for: live.id)
        let showFeedback = showRecap
            && progress?.feedbackSubmitted != true
            && progress?.feedbackSkipped != true
        if showHostEdit || showRecap || showFeedback {
            Section {
                if showHostEdit {
                    Button {
                        showContentEditor = true
                    } label: {
                        Label(ActivityCardStatus.refineContent, systemImage: "square.and.pencil")
                    }
                }

                if showFeedback {
                    Button {
                        showFeedbackSheet = true
                    } label: {
                        Label(ActivityJourneyCopy.shareFeedback, systemImage: "hand.thumbsup")
                    }
                }

                if showRecap {
                    let recapDone = progress?.recapPublished == true || progress?.recapSkipped == true
                    if !recapDone {
                        Button {
                            openRecapCompose(for: live)
                        } label: {
                            Label(ActivityDetailCopy.recapCTA, systemImage: "square.and.pencil")
                        }
                        Button(ActivityExperienceFeedbackCopy.skip, role: .cancel) {
                            model.skipActivityRecap(live.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Hero / chrome

    func hero(_ activity: Activity) -> some View {
        let chip = ActivityDetailWeatherPresentation.heroChip(for: activity)

        return DetailHeroChrome {
            ActivityDetailHeroGallery(
                activity: activity,
                onEditGallery: isHost ? { showContentEditor = true } : nil
            )
        } chip: { onMedia in
            DetailHeroInfoChip(
                title: chip.title,
                systemImage: chip.systemImage,
                onMedia: onMedia
            )
            .accessibilityLabel(chip.accessibilityLabel)
        }
    }

    func titleBlock(_ activity: Activity) -> some View {
        VStack(alignment: .leading) {
            Text(activity.title)
                .font(.title2.weight(.bold))

            Text(Formatters.activityPitch(from: activity.summary))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(3)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    func sectionBlock(
        section: ActivityDetailSection,
        blueprint: ActivityDetailBlueprint
    ) -> some View {
        switch section.id {
        case .plan:
            ActivityDetailTimelineCard(items: blueprint.timeline)
        case .fee:
            ActivityDetailFeeCard(
                included: blueprint.feeIncluded,
                excluded: blueprint.feeExcluded,
                refundNotes: blueprint.refundNotes
            )
        case .prep:
            prepBlock(blueprint)
        case .notes:
            ActivityDetailNumberedNotes(notes: blueprint.registrationNotes)
        }
    }

    @ViewBuilder
    func prepBlock(_ blueprint: ActivityDetailBlueprint) -> some View {
        VStack(alignment: .leading) {
            if !blueprint.gear.isEmpty {
                ActivityDetailGearGrid(items: blueprint.gear)
            }
            if !blueprint.gear.isEmpty, !blueprint.prepNotes.isEmpty {
                Divider()
            }
            if !blueprint.prepNotes.isEmpty {
                ActivityDetailNumberedNotes(notes: blueprint.prepNotes)
            }
        }
    }
}
