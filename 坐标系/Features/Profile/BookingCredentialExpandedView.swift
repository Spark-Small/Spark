//
//  BookingCredentialExpandedView.swift
//  坐标系
//
//  「我的」陪玩凭证展开页：票面头图 + 预约信息 / 联系 / 订单操作（原「管理预约」并入本页）。
//

import SwiftUI

struct BookingCredentialExpandedView: View {
    let recordID: BuddyBookingRecord.ID

    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(RefundFlowService.self) private var refunds
    @Environment(WalletPassStore.self) private var passStore
    @Environment(\.dismiss) private var dismiss

    @State private var showAddToWallet = false
    @State private var showReschedule = false
    @State private var refundTarget: BuddyBookingRecord?
    @State private var presentedRefundRequestID: UUID?
    @State private var confirmCancel = false
    @State private var confirmDelete = false
    @State private var peerContactRoute: PeerContactRoute?

    private var record: BuddyBookingRecord? {
        buddies.bookingRecords.first { $0.id == recordID }
    }

    private var relatedPass: PassRecord? {
        guard let record else { return nil }
        return passStore.resolvedBookingPass(for: record.id)
    }

    private var canOfferWallet: Bool {
        relatedPass?.voided == false
    }

    private var coverPhoto: CommunityPhotoRef? {
        guard let record else { return nil }
        return buddies.item(for: record.companionNickname)?.profile.coverPhoto
    }

    var body: some View {
        Group {
            if let record {
                credentialForm(record)
            } else {
                ContentUnavailableView(
                    "预约不可用",
                    systemImage: "ticket",
                    description: Text("这张凭证关联的预约已无法加载。")
                )
                .onAppear { dismiss() }
            }
        }
        .navigationTitle("陪玩凭证")
        .navigationBarTitleDisplayMode(.inline)
        .peerContactDestination(route: $peerContactRoute)
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
        .sheet(isPresented: $showReschedule) {
            if let record {
                BookingRescheduleSheet(record: record) { scheduledAt, hours in
                    buddies.rescheduleBooking(record.id, scheduledAt: scheduledAt, hours: hours)
                    showReschedule = false
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .sheet(item: $refundTarget) { target in
            RefundRequestSheet.booking(target) { reason, detail in
                if let requestID = buddies.refundBooking(target.id, reason: reason, detail: detail) {
                    presentedRefundRequestID = requestID
                }
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: Binding(
            get: { presentedRefundRequestID != nil },
            set: { if !$0 { presentedRefundRequestID = nil } }
        )) {
            if let requestID = presentedRefundRequestID {
                RefundStatusSheet(requestID: requestID)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .alert("取消预约？", isPresented: $confirmCancel) {
            Button("取消预约", role: .destructive) {
                guard let record else { return }
                if record.canWithdraw {
                    buddies.withdrawPendingBooking(record.id)
                } else {
                    buddies.cancelBooking(record.id)
                }
            }
            Button("保留预约", role: .cancel) {}
        } message: {
            Text("取消后无法恢复，如已支付请先确认退款规则。")
        }
        .alert("删除这条预约记录？", isPresented: $confirmDelete) {
            Button("删除记录", role: .destructive) {
                if let record {
                    buddies.deleteBooking(record.id)
                    dismiss()
                }
            }
            Button("保留记录", role: .cancel) {}
        } message: {
            Text("删除后无法恢复。")
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
            .platformSheetConfirmationToolbar("完成") {
                showAddToWallet = false
            }
        }
        .platformSheet(.confirm)
    }

    @ViewBuilder
    private func credentialForm(_ record: BuddyBookingRecord) -> some View {
        let schedule = WalletPassFaceFactory.scheduleFields(from: record.scheduledAt)
        let isVoided = relatedPass?.voided == true
        let statusText = isVoided ? "已作废" : record.statusLabel

        Form {
            Section {
                ProfileBookingCredentialCard(
                    record: record,
                    photo: coverPhoto,
                    voided: isVoided,
                    embedsNotes: false,
                    embedsHeader: false
                )
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section {
                VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                    Text(record.companionNickname)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(statusText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(
                            isVoided ? Color.secondary : bookingStatusColor(record.status)
                        )
                }
                .accessibilityElement(children: .combine)

                LabeledContent("费用", value: record.priceText)
                LabeledContent("时间", value: schedule.label)
                LabeledContent("日期", value: schedule.value)
                LabeledContent("时长", value: "\(record.hours) 小时")
                if let slot = record.selectedSlotLabel, !slot.isEmpty {
                    LabeledContent("档期", value: slot)
                }
            }

            Section("订单记录") {
                LabeledContent(
                    "下单",
                    value: Formatters.activityDate.string(from: record.bookedAt)
                )
                if let paidAt = record.paidAt {
                    LabeledContent(
                        "支付",
                        value: Formatters.activityDate.string(from: paidAt)
                    )
                }
                if let completedAt = record.completedAt {
                    LabeledContent(
                        "完成",
                        value: Formatters.activityDate.string(from: completedAt)
                    )
                }
            }

            Section {
                Button("联系陪玩", systemImage: "message") {
                    contact(record.companionNickname)
                }
                if let item = buddies.item(for: record.companionNickname) {
                    NavigationLink {
                        BuddyDetailRouteView(item: item)
                    } label: {
                        Label("查看资料", systemImage: "person.crop.circle")
                    }
                }
                if shouldOfferReissue(record) {
                    Button("补发预约凭证", systemImage: "ticket") {
                        _ = passStore.issueBookingTicket(for: record)
                    }
                } else if record.status == .pendingConfirm || record.status == .awaitingPayment {
                    Text("支付完成后将生成预约凭证")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if hasPrimaryActions(record) {
                Section("订单操作") {
                    bookingActions(record)
                }
            }

            if record.canSimulateCounterpart {
                Section {
                    Button("模拟对方接单", systemImage: "hand.thumbsup") {
                        buddies.acceptBooking(record.id)
                    }
                    Button("模拟对方拒单", systemImage: "hand.thumbsdown", role: .destructive) {
                        buddies.declineBooking(record.id)
                    }
                } header: {
                    Text("本地演示")
                } footer: {
                    Text("正式产品由陪玩端确认；此处可手动推进状态机。")
                }
            }

            Section {
                Button("删除记录", systemImage: "trash", role: .destructive) {
                    confirmDelete = true
                }
            }
        }
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollEdgeEffectStyle(.soft, for: .top)
    }

    private func shouldOfferReissue(_ record: BuddyBookingRecord) -> Bool {
        let eligibleStatus =
            record.status == .paid
            || record.status == .inProgress
            || record.status == .completed
        guard eligibleStatus else { return false }
        guard let pass = relatedPass else { return true }
        return pass.voided
    }

    private func hasPrimaryActions(_ record: BuddyBookingRecord) -> Bool {
        record.canPay
            || record.canWithdraw
            || record.canMarkInProgress
            || record.canComplete
            || record.canRefund
            || record.canReschedule
            || (record.status == .completed && !TrustService.shared.hasCheckedIn(bookingID: record.id))
    }

    @ViewBuilder
    private func bookingActions(_ record: BuddyBookingRecord) -> some View {
        if record.canPay {
            Button("去支付", systemImage: "yensign.circle") {
                buddies.beginPayment(record.id)
            }
        }
        if record.canMarkInProgress {
            Button("开始履约", systemImage: "play.fill") {
                buddies.markInProgress(record.id)
            }
        }
        if record.canComplete {
            Button("完成订单", systemImage: "checkmark.circle") {
                buddies.completeBooking(record.id)
            }
        }
        if record.status == .completed, !TrustService.shared.hasCheckedIn(bookingID: record.id) {
            Button("履约确认", systemImage: "checkmark.shield") {
                buddies.pendingSafetyCheckInBookingID = record.id
            }
        }
        if record.canReschedule {
            Button("改期", systemImage: "calendar") {
                showReschedule = true
            }
        }
        if record.canRefund, !refunds.isRefunding(orderID: record.id) {
            Button("申请退款", systemImage: "arrow.uturn.backward", role: .destructive) {
                refundTarget = record
            }
        }
        if record.canWithdraw || record.status == .paid || record.status == .inProgress {
            Button("取消预约", systemImage: "xmark.circle", role: .destructive) {
                confirmCancel = true
            }
        }
    }

    private func contact(_ nickname: String) {
        guard let record else { return }
        peerContactRoute = app.openPeerContact(
            with: nickname,
            context: .forBooking(record)
        )
    }
}
