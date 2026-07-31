//
//  ActivityCredentialExpandedView.swift
//  坐标系
//
//  「我的」活动凭证 Zoom 展开页：票面头图 + Form 信息 / 安排 / 细则；Wallet 在右上角。
//  安排与细则用纯 Form 行（无步骤序号 / 图标），与陪玩凭证视觉一致。
//

import SwiftUI

struct ActivityCredentialExpandedView: View {
    let activityID: Activity.ID

    @Environment(ActivitiesModel.self) private var activities
    @Environment(WalletPassStore.self) private var passStore
    @State private var showAddToWallet = false
    @State private var showActivityDetail = false

    private var activity: Activity? {
        activities.activity(id: activityID)
    }

    private var relatedPass: PassRecord? {
        guard let activity else { return nil }
        return passStore.resolvedActivityPass(for: activity)
    }

    private var canOfferWallet: Bool {
        relatedPass?.voided == false
    }

    var body: some View {
        Group {
            if let activity {
                credentialForm(activity)
            } else {
                ContentUnavailableView(
                    "活动不可用",
                    systemImage: "ticket",
                    description: Text("这张凭证关联的活动已无法加载。")
                )
            }
        }
        .navigationTitle("活动凭证")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if canOfferWallet {
                    Button {
                        showAddToWallet = true
                    } label: {
                        Image(systemName: "wallet.bifold")
                    }
                    .accessibilityLabel("加入 Apple Wallet")
                }
            }
        }
        .sheet(isPresented: $showAddToWallet) {
            addToWalletSheet
        }
        .navigationDestination(isPresented: $showActivityDetail) {
            ActivityDetailView(activityID: activityID)
        }
    }

    private var addToWalletSheet: some View {
        NavigationStack {
            Form {
                if let pass = relatedPass, !pass.voided {
                    Section {
                        WalletPassAddToWalletControl(pass: pass)
                    } footer: {
                        Text(WalletPassKitCopy.addFooter)
                    }
                } else {
                    Section {
                        ContentUnavailableView(
                            "暂无可加入的通行证",
                            systemImage: "wallet.bifold",
                            description: Text(WalletPassKitCopy.addFooter)
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .navigationTitle("加入 Apple Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { showAddToWallet = false }
                }
            }
        }
        .platformSheet(.confirm)
    }

    @ViewBuilder
    private func credentialForm(_ activity: Activity) -> some View {
        let blueprint = ActivityDetailBlueprint.make(for: activity)
        let timeline = Array(blueprint.timeline.prefix(6))
        let notes = WalletPassFaceFactory.detailNotes(from: blueprint, limit: 6)
        let schedule = WalletPassFaceFactory.scheduleFields(from: activity.date)

        Form {
            Section {
                ProfileActivityCredentialCard(
                    activity: activity,
                    voided: relatedPass?.voided == true,
                    embedsNotes: false,
                    embedsHeader: false,
                    onOpenDetail: { showActivityDetail = true }
                )
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                    Text(activity.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(WalletPassFaceFactory.attendanceHint(for: activity))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                LabeledContent("时间", value: schedule.label)
                LabeledContent("日期", value: schedule.value)
            }

            if !timeline.isEmpty {
                Section {
                    ForEach(timeline) { item in
                        timelineRow(item)
                    }
                } header: {
                    Text("活动安排")
                }
            }

            if !notes.isEmpty {
                Section {
                    ForEach(Array(notes.enumerated()), id: \.offset) { _, note in
                        Text(note)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } header: {
                    Text("细则注意事项")
                }
            }
        }
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    private func timelineRow(_ item: ActivityDetailTimelineItem) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                Text(item.time)
                    .monospacedDigit()
                Text(item.title)
            }
            .font(.body)
            .foregroundStyle(.primary)

            if !item.detail.isEmpty {
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.time)，\(item.title)。\(item.detail)")
    }
}
