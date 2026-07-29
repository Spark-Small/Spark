//
//  BuddyRecordDetailViews.swift
//  坐标系
//
//  邀约 / 预约订单详情：Form 承载状态与操作（系统级，无自定义仪表盘）。
//

import SwiftUI

// MARK: - Booking detail

struct BuddyBookingDetailView: View {
    let recordID: BuddyBookingRecord.ID

    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var showReschedule = false

    private var record: BuddyBookingRecord? {
        buddies.bookingRecords.first { $0.id == recordID }
    }

    var body: some View {
        Group {
            if let record {
                Form {
                    Section {
                        LabeledContent("陪玩", value: record.companionNickname)
                        LabeledContent("状态") {
                            Text(record.statusLabel)
                                .foregroundStyle(bookingStatusColor(record.status))
                                .fontWeight(.semibold)
                        }
                        LabeledContent("费用", value: record.priceText)
                    }

                    Section("档期") {
                        LabeledContent(
                            "开始",
                            value: "\(Formatters.monthDay.string(from: record.scheduledAt)) \(Formatters.shortTime.string(from: record.scheduledAt))"
                        )
                        LabeledContent("时长", value: "\(record.hours) 小时")
                        if let slot = record.selectedSlotLabel, !slot.isEmpty {
                            LabeledContent("档期", value: slot)
                        }
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
                        Button("删除记录", role: .destructive) {
                            buddies.deleteBooking(record.id)
                            dismiss()
                        }
                    }
                }
            } else {
                ContentUnavailableView("订单不存在", systemImage: "person.badge.clock")
                    .onAppear { dismiss() }
            }
        }
        .navigationTitle("预约详情")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .sheet(isPresented: $showReschedule) {
            if let record {
                BookingRescheduleSheet(record: record) { scheduledAt, hours in
                    buddies.rescheduleBooking(record.id, scheduledAt: scheduledAt, hours: hours)
                    showReschedule = false
                }
            }
        }
        .sheet(item: Binding(
            get: { buddies.pendingPaymentBooking },
            set: { if $0 == nil { buddies.cancelPendingPayment() } }
        )) { paymentRecord in
            BookingPaymentSheet(
                record: paymentRecord,
                onConfirm: {
                    buddies.confirmPayment(paymentRecord.id)
                    let greeting =
                        "你好！我想预约 \(Formatters.monthDay.string(from: paymentRecord.scheduledAt)) "
                        + "\(Formatters.shortTime.string(from: paymentRecord.scheduledAt)) 开始的 \(paymentRecord.hours) 小时陪玩，方便确认一下吗？"
                    if let convo = app.startDirectChat(
                        with: paymentRecord.companionNickname,
                        greeting: greeting
                    ) {
                        app.openMessages(conversationID: convo.id)
                    }
                },
                onCancel: {
                    buddies.cancelPendingPayment()
                }
            )
        }
    }

    private func hasPrimaryActions(_ record: BuddyBookingRecord) -> Bool {
        record.canPay
            || record.canWithdraw
            || record.canMarkInProgress
            || record.canComplete
            || record.canRefund
            || record.canReschedule
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
        if record.canReschedule {
            Button("改期", systemImage: "calendar") {
                showReschedule = true
            }
        }
        if record.canRefund {
            Button("申请退款", systemImage: "arrow.uturn.backward", role: .destructive) {
                buddies.refundBooking(record.id)
            }
        }
        if record.canWithdraw || record.status == .paid || record.status == .inProgress {
            Button("取消预约", systemImage: "xmark.circle", role: .destructive) {
                if record.canWithdraw {
                    buddies.withdrawPendingBooking(record.id)
                } else {
                    buddies.cancelBooking(record.id)
                }
            }
        }
    }

    private func contact(_ nickname: String) {
        if let convo = app.startDirectChat(
            with: nickname,
            greeting: "你好，想确认一下预约安排，最近方便吗？"
        ) {
            app.openMessages(conversationID: convo.id)
        }
    }
}

func bookingStatusColor(_ status: BookingOrderStatus) -> Color {
    switch status {
    case .pendingConfirm: .orange
    case .awaitingPayment: PlatformStatus.warning
    case .paid: .blue
    case .inProgress: .indigo
    case .completed: PlatformStatus.success
    case .refunded, .cancelled: .secondary
    }
}

// MARK: - Invite detail

struct BuddyInviteDetailView: View {
    let recordID: BuddyInviteRecord.ID

    @Environment(BuddiesModel.self) private var buddies
    @Environment(ActivitiesModel.self) private var activities
    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    private var record: BuddyInviteRecord? {
        buddies.inviteRecords.first { $0.id == recordID }
    }

    private var relatedActivity: Activity? {
        guard let record else { return nil }
        if let id = record.relatedActivityID {
            return activities.activity(id: id)
        }
        return activities.activity(matchingTitle: record.activityTitle)
    }

    var body: some View {
        Group {
            if let record {
                Form {
                    Section {
                        LabeledContent("对象", value: record.nickname)
                        LabeledContent("状态") {
                            Text(record.status.rawValue)
                                .foregroundStyle(inviteStatusColor(record.status))
                                .fontWeight(.semibold)
                        }
                        LabeledContent("活动", value: record.activityTitle)
                        LabeledContent(
                            "发出",
                            value: Formatters.activityDate.string(from: record.sentAt)
                        )
                    }

                    Section {
                        Button("发消息", systemImage: "message") {
                            if let convo = app.startDirectChat(with: record.nickname) {
                                app.openMessages(conversationID: convo.id)
                            }
                        }
                        if let activity = relatedActivity {
                            NavigationLink {
                                ActivityDetailView(activity: activity)
                            } label: {
                                Label("查看活动", systemImage: "calendar")
                            }
                            if record.status == .accepted {
                                Button("进入活动群", systemImage: "person.3") {
                                    app.openActivityGroupChat(for: activity)
                                }
                            }
                        }
                        if let buddy = buddies.item(for: record.nickname) {
                            NavigationLink {
                                BuddyDetailRouteView(item: buddy)
                            } label: {
                                Label("搭子资料", systemImage: "person.crop.circle")
                            }
                        }
                    }

                    if record.status == .pending {
                        Section {
                            Button("模拟对方接受", systemImage: "checkmark.circle") {
                                buddies.acceptInvite(record.id)
                            }
                            Button("模拟对方婉拒", systemImage: "xmark.circle", role: .destructive) {
                                buddies.declineInvite(record.id)
                            }
                        } header: {
                            Text("本地演示")
                        } footer: {
                            Text("正式产品由对方回执；此处可手动推进状态。")
                        }
                    }

                    Section {
                        Button("删除记录", role: .destructive) {
                            buddies.deleteInvite(record.id)
                            dismiss()
                        }
                    }
                }
            } else {
                ContentUnavailableView("邀约不存在", systemImage: "paperplane")
                    .onAppear { dismiss() }
            }
        }
        .navigationTitle("邀约详情")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}

func inviteStatusColor(_ status: BuddyInviteStatus) -> Color {
    switch status {
    case .pending: .orange
    case .accepted: PlatformStatus.success
    case .declined: .secondary
    }
}

// Re-export reschedule sheet used by list + detail
struct BookingRescheduleSheet: View {
    let record: BuddyBookingRecord
    var onSave: (Date, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scheduledAt: Date
    @State private var hours: Int

    init(record: BuddyBookingRecord, onSave: @escaping (Date, Int) -> Void) {
        self.record = record
        self.onSave = onSave
        _scheduledAt = State(initialValue: max(record.scheduledAt, Date()))
        _hours = State(initialValue: record.hours)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("改期") {
                    DatePicker("开始时间", selection: $scheduledAt, in: Date()...)
                    Stepper("时长 \(hours) 小时", value: $hours, in: 1...8)
                }
            }
            .navigationTitle(record.companionNickname)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(scheduledAt, hours)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .platformSheet(.confirm)
    }
}
