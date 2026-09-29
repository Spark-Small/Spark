//
//  BuddyRecordDetailViews.swift
//  坐标系
//
//  邀约详情；预约管理入口转发至陪玩凭证页。改期 Sheet 仍在此文件。
//

import SwiftUI
import CoordinateModels

// MARK: - Booking detail

func bookingStatusColor(_ status: BookingOrderStatus) -> Color {
    switch status {
    case .pendingConfirm: .orange
    case .awaitingPayment: PlatformStatus.warning
    case .paid: .blue
    case .inProgress: .indigo
    case .completed: PlatformStatus.success
    case .refunding: PlatformStatus.warning
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
    @Environment(\.activityZoomNamespace) private var zoomNamespace
    @Environment(\.dismiss) private var dismiss
    @State private var peerContactRoute: PeerContactRoute?

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
                        Button {
                            peerContactRoute = app.openPeerContact(
                                with: record.nickname,
                                context: .inviteBuddy(activityTitle: record.activityTitle)
                            )
                        } label: {
                            Label(
                                app.peerContactActionTitle(
                                    for: record.nickname,
                                    context: .inviteBuddy(activityTitle: record.activityTitle)
                                ),
                                systemImage: "message"
                            )
                        }
                        if let activity = relatedActivity {
                            relatedActivityLink(activity)
                            if record.status == .accepted, app.activities.isJoined(activity.id) {
                                NavigationLink {
                                    ActivityCredentialExpandedView(activityID: activity.id)
                                        .toolbarVisibility(.hidden, for: .tabBar)
                                } label: {
                                    Label(ActivityDetailCopy.credentialViewAction, systemImage: "ticket.fill")
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
                        Button("删除记录", systemImage: "trash", role: .destructive) {
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
        .peerContactDestination(route: $peerContactRoute)
    }

    @ViewBuilder
    private func relatedActivityLink(_ activity: Activity) -> some View {
        if let zoomNamespace {
            ActivityZoomNavigationLink(activity: activity, namespace: zoomNamespace) {
                Label("查看活动", systemImage: "calendar")
            }
        } else {
            NavigationLink {
                ActivityDetailView(activity: activity)
                    .toolbarVisibility(.hidden, for: .tabBar)
            } label: {
                Label("查看活动", systemImage: "calendar")
            }
        }
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
