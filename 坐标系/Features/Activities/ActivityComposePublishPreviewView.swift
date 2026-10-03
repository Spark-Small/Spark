//
//  ActivityComposePublishPreviewView.swift
//  坐标系
//
//  发布前预览：与对外活动详情同构；发起人未写的分区显示「待补充」，
//  不用类别模板冒充已填写内容。发布后对外页再按类型套用默认模板。
//

import SwiftUI
import CoordinateModels

struct ActivityComposePublishPreviewView: View {
    let activity: Activity
    /// 封面以外的配图（与详情相册 extras 一致）。
    var galleryExtraNames: [String]
    var hostNote: String?
    var confirmTitle: String
    var onConfirm: () -> Void

    @Environment(ActivitiesModel.self) private var activities
    @State private var expandedSections: Set<ActivityDetailSectionID> = []

    /// 类别标题 + 分区顺序（不含模板正文）。
    private var sectionChrome: ActivityDetailBlueprint {
        ActivityDetailBlueprint.templateBlueprint(for: activity)
    }

    /// 仅合并发起人本地覆盖；用于判断 / 展示已填写分区。
    private var authoredBlueprint: ActivityDetailBlueprint {
        ActivityDetailBlueprint.make(for: activity)
    }

    private var joinTitle: String {
        ActivityDetailCopy.joinButtonTitle(
            free: activity.isFree,
            almostFull: activity.isAlmostFull,
            remaining: activity.remainingSpots,
            full: activity.isFull,
            waitlisted: false,
            hasOpenSpotFromWaitlist: false
        )
    }

    var body: some View {
        Form {
            Section {
                hero
                    .platformFullBleedMediaFormRow()
            }

            if !pendingSections.isEmpty {
                Section {
                    ForEach(pendingSections) { section in
                        Label(
                            ActivityComposeCopy.pendingChecklistRowTitle(sectionTitle: section.title),
                            systemImage: "pencil.and.list.clipboard"
                        )
                        .foregroundStyle(.secondary)
                    }
                    if !activity.isFree {
                        Text(ActivityComposeCopy.pendingChecklistPaidEmphasis)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text(ActivityComposeCopy.pendingChecklistHeader)
                } footer: {
                    Text(ActivityComposeCopy.pendingChecklistFooter)
                }
            }

            Section {
                titleBlock

                ActivityDetailDecisionCard(
                    activity: activity,
                    viewerWaitlisted: false,
                    canAddCalendarReminder: false,
                    hostNote: hostNote ?? authoredBlueprint.hostNote,
                    matchedFriends: [],
                    onPeople: {}
                )
            }

            Section {
                ActivityDetailHostTrustRow(
                    trust: ActivityHostTrust.make(
                        hostName: activity.hostName,
                        liveHostedCount: activities.hostedCount(for: activity.hostName)
                    ),
                    onHost: {},
                    onChat: {}
                )
            } header: {
                Text(ActivityDetailCopy.peopleHostRole)
            }

            ForEach(sectionChrome.sections) { section in
                Section {
                    ActivityDetailCollapsibleSection(
                        title: section.title,
                        summary: sectionSummary(for: section.id),
                        isExpanded: expandedBinding(for: section.id)
                    ) {
                        sectionBlock(section)
                    }
                }
            }
        }
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .background(PlatformSurface.groupedPage.ignoresSafeArea())
        .navigationTitle(activity.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .platformDetailBottomBar {
            DetailBottomActionBar {
                Button(joinTitle) {}
                    .activityDetailBottomPrimaryCTA()
                    .disabled(true)
                    .accessibilityLabel("\(joinTitle)，预览不可参加")
            }
        }
        .platformSheetConfirmationToolbar(
            confirmTitle,
            emphasizesWhenEnabled: true,
            action: onConfirm
        )
    }

    /// 发起人尚未覆盖的分区（预览行动清单）。
    private var pendingSections: [ActivityDetailSection] {
        sectionChrome.sections.filter {
            !ActivityDetailBlueprint.hasHostAuthoredContent(for: $0.id, activity: activity)
        }
    }

    // MARK: - Blocks

    private var hero: some View {
        let chip = ActivityDetailWeatherPresentation.heroChip(for: activity)

        return DetailHeroChrome {
            ActivityDetailHeroGallery(
                activity: activity,
                galleryExtraNames: galleryExtraNames
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

    private var titleBlock: some View {
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

    @ViewBuilder
    private func sectionBlock(_ section: ActivityDetailSection) -> some View {
        if ActivityDetailBlueprint.hasHostAuthoredContent(for: section.id, activity: activity) {
            authoredSectionBody(section.id)
        } else {
            ActivityDetailPendingFillBlock(categoryTitle: activity.category.title)
        }
    }

    @ViewBuilder
    private func authoredSectionBody(_ id: ActivityDetailSectionID) -> some View {
        let blueprint = authoredBlueprint
        switch id {
        case .plan:
            ActivityDetailTimelineCard(items: blueprint.timeline)
        case .fee:
            ActivityDetailFeeCard(
                included: blueprint.feeIncluded,
                excluded: blueprint.feeExcluded,
                refundNotes: blueprint.refundNotes
            )
        case .prep:
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
        case .notes:
            ActivityDetailNumberedNotes(notes: blueprint.registrationNotes)
        }
    }

    private func sectionSummary(for id: ActivityDetailSectionID) -> String {
        if ActivityDetailBlueprint.hasHostAuthoredContent(for: id, activity: activity) {
            return ActivityDetailBlueprint.sectionSummary(
                for: id,
                activity: activity,
                blueprint: authoredBlueprint
            )
        }
        return ActivityComposeCopy.pendingFillSummary
    }

    private func expandedBinding(for sectionID: ActivityDetailSectionID) -> Binding<Bool> {
        Binding(
            get: { expandedSections.contains(sectionID) },
            set: { isExpanded in
                if isExpanded {
                    expandedSections.insert(sectionID)
                } else {
                    expandedSections.remove(sectionID)
                }
            }
        )
    }
}
