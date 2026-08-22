//
//  ActivityCredentialExpandedView.swift
//  坐标系
//
//  「我的」活动凭证 Zoom 展开页：票面头图 + Form 信息 / 安排 / 细则；Wallet 在右上角。
//  取消参加 / 退款 / 主办取消与活动详情、管理页同一套弹窗与业务闭环。
//

import SwiftUI

struct ActivityCredentialExpandedView: View {
    let activityID: Activity.ID

    @Environment(AppModel.self) private var app
    @Environment(ActivitiesModel.self) private var activities
    @Environment(WalletPassStore.self) private var passStore
    @Environment(RefundFlowService.self) private var refunds
    @Environment(\.dismiss) private var dismiss

    @State private var showAddToWallet = false
    @State private var showActivityDetail = false
    @State private var cancelRefundActivityID: Activity.ID?
    @State private var cancelUnpaidActivityID: Activity.ID?
    @State private var cancelAndRefundOrder: ActivityOrder?
    @State private var presentedRefundRequestID: UUID?
    @State private var showCancelHostAlert = false
    @State private var actionIssueMessage: String?

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

    private var isHost: Bool {
        activity.map(activities.isHost) ?? false
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
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .alert(
            ActivityDetailCopy.cancelWithRefundTitle,
            isPresented: Binding(
                get: { cancelRefundActivityID != nil },
                set: { if !$0 { cancelRefundActivityID = nil } }
            )
        ) {
            Button("暂不取消", role: .cancel) {
                cancelRefundActivityID = nil
            }
            Button(ActivityDetailCopy.cancelOnly) {
                if let id = cancelRefundActivityID {
                    app.cancelActivityRegistration(id, refundIfPaid: false)
                }
                cancelRefundActivityID = nil
            }
            Button(ActivityDetailCopy.cancelWithRefundConfirm, role: .destructive) {
                if let id = cancelRefundActivityID,
                   let order = ActivityPaymentStore.paidOrder(for: id) {
                    cancelAndRefundOrder = order
                }
                cancelRefundActivityID = nil
            }
        } message: {
            Text(ActivityDetailCopy.cancelWithRefundMessage)
        }
        .alert(
            ActivityDetailCopy.cancelUnpaidTitle,
            isPresented: Binding(
                get: { cancelUnpaidActivityID != nil },
                set: { if !$0 { cancelUnpaidActivityID = nil } }
            )
        ) {
            Button(ActivityDetailCopy.cancelUnpaidKeep, role: .cancel) {
                cancelUnpaidActivityID = nil
            }
            Button(ActivityDetailCopy.cancelUnpaidConfirm, role: .destructive) {
                if let id = cancelUnpaidActivityID {
                    app.cancelActivityRegistration(id)
                }
                cancelUnpaidActivityID = nil
            }
        } message: {
            Text(ActivityDetailCopy.cancelUnpaidMessage)
        }
        .sheet(item: $cancelAndRefundOrder) { order in
            let activity = activities.activity(id: order.activityID)
            let notes = activity.map { ActivityDetailBlueprint.make(for: $0).refundNotes } ?? []
            RefundRequestSheet.activityOrder(order, activity: activity, refundNotes: notes) { reason, detail in
                submitCancelAndRefund(order: order, reason: reason, detail: detail)
            }
        }
        .sheet(isPresented: Binding(
            get: { presentedRefundRequestID != nil },
            set: { if !$0 { presentedRefundRequestID = nil } }
        )) {
            if let requestID = presentedRefundRequestID {
                RefundStatusSheet(requestID: requestID)
            }
        }
        .alert(
            ActivityDetailCopy.hostManageCancelAlertTitle,
            isPresented: $showCancelHostAlert
        ) {
            Button(ActivityDetailCopy.hostManageCancelActivity, role: .destructive) {
                app.cancelHostedActivity(activityID)
                dismiss()
            }
            Button("保留活动", role: .cancel) {}
        } message: {
            Text(
                ActivityDetailCopy.hostManageCancelAlertMessage(
                    title: activity?.title ?? "该活动"
                )
            )
        }
        .alert("无法退款", isPresented: Binding(
            get: { actionIssueMessage != nil },
            set: { if !$0 { actionIssueMessage = nil } }
        )) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(actionIssueMessage ?? "")
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
            .toolbarVisibility(.hidden, for: .tabBar)
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
        let isVoided = relatedPass?.voided == true
        let joined = activities.isJoined(activity.id)
        let ended = activity.isLifecycleEnded

        Form {
            Section {
                ProfileActivityCredentialCard(
                    activity: activity,
                    voided: isVoided,
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

            if !isVoided, hasPrimaryActions(joined: joined, ended: ended) {
                Section("活动操作") {
                    activityActions(activity, joined: joined, ended: ended)
                }
            }

            if !isVoided, isHost, !ended {
                Section {
                    Button(ActivityDetailCopy.hostManageCancelActivity, role: .destructive) {
                        showCancelHostAlert = true
                    }
                } footer: {
                    Text(ActivityDetailCopy.hostManageCancelHint)
                }
            }
        }
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    private func hasPrimaryActions(joined: Bool, ended: Bool) -> Bool {
        if isHost { return true }
        if joined, !ended { return true }
        if joined || isHost, shouldOfferReissue { return true }
        return false
    }

    private var shouldOfferReissue: Bool {
        guard let activity, relatedPass == nil || relatedPass?.voided == true else { return false }
        return activities.isJoined(activity.id) || isHost
    }

    @ViewBuilder
    private func activityActions(
        _ activity: Activity,
        joined: Bool,
        ended: Bool
    ) -> some View {
        if isHost {
            NavigationLink {
                ActivityHostManageView(activityID: activity.id)
            } label: {
                Label(ActivityDetailCopy.hostManageTitle, systemImage: "slider.horizontal.3")
            }

            Button(ActivityDetailCopy.openGroupChat, systemImage: "bubble.left.and.bubble.right") {
                app.openActivityGroupChat(for: activity)
            }
        } else if joined {
            Button(ActivityDetailCopy.openGroupChat, systemImage: "bubble.left.and.bubble.right") {
                app.openActivityGroupChat(for: activity)
            }

            if !ended {
                Button(ActivityDetailCopy.cancelRegistration, systemImage: "xmark.circle", role: .destructive) {
                    requestCancelRegistration(activity)
                }
            }
        }

        if shouldOfferReissue {
            Button("补发活动凭证", systemImage: "ticket") {
                reissue(activity)
            }
        }
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

    private func requestCancelRegistration(_ activity: Activity) {
        if ActivityPaymentStore.hasPaid(for: activity.id) {
            cancelRefundActivityID = activity.id
        } else {
            cancelUnpaidActivityID = activity.id
        }
    }

    /// 与活动详情一致：填退款申请并确认后，进入退款流程 + 完成后取消参加
    private func submitCancelAndRefund(order: ActivityOrder, reason: String, detail: String) {
        let activity = activities.activity(id: order.activityID)
        let notes = activity.map { ActivityDetailBlueprint.make(for: $0).refundNotes } ?? []
        let result = refunds.submitActivityRefund(
            order: order,
            activity: activity,
            refundNotes: notes,
            reason: reason,
            detail: detail,
            cancelRegistration: true,
            onCancelRegistration: { id in
                app.cancelActivityRegistration(id, refundIfPaid: false)
            }
        )
        switch result {
        case .success(let record):
            presentedRefundRequestID = record.id
        case .failure(let error):
            actionIssueMessage = error.localizedDescription
        }
    }

    private func reissue(_ activity: Activity) {
        if let order = ActivityPaymentStore.paidOrder(for: activity.id) {
            _ = passStore.issueActivityTicket(order: order, activity: activity)
        } else {
            _ = passStore.issueActivityAttendanceTicket(for: activity)
        }
    }
}
