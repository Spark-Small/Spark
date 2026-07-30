//
//  ActivityHostManageView.swift
//  坐标系
//
//  发起人行程管理页：名额、改期、内容、取消活动。
//

import SwiftUI

/// 行程 / 详情共用的发起人管理页（Push 呈现）
struct ActivityHostManageView: View {
    let activityID: Activity.ID

    @Environment(ActivitiesModel.self) private var model
    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var capacity: Int = 8
    @State private var date = Date()
    @State private var notifyNote = ""
    @State private var showCancelAlert = false
    @State private var showContentEditor = false
    @State private var contentRevision = 0

    private var live: Activity? {
        model.activity(id: activityID)
    }

    var body: some View {
        Group {
            if let live {
                manageForm(live)
            } else {
                ContentUnavailableView("活动不存在", systemImage: "calendar")
                    .onAppear { dismiss() }
            }
        }
        .navigationTitle(ActivityDetailCopy.hostManageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .sheet(isPresented: $showContentEditor) {
            if let live {
                ActivityDetailContentEditorSheet(activity: live) {
                    contentRevision += 1
                }
            }
        }
    }

    @ViewBuilder
    private func manageForm(_ live: Activity) -> some View {
        let _ = contentRevision
        let orders = ActivityPaymentStore.orders(for: live.id).filter { $0.status == .paid || $0.status == .refunding }

        Form {
            Section {
                VStack(alignment: .leading) {
                    Text(live.title)
                        .font(.subheadline.weight(.semibold))
                    Text(Formatters.activityEventTime(from: live.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(live.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Label("\(live.joined)/\(live.capacity)", systemImage: "person.2")
                        Label(live.isFree ? "免费" : live.fee, systemImage: "yensign.circle")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Section {
                LabeledContent("当前报名") {
                    Text("\(live.joined)/\(live.capacity) 人")
                }
                Stepper(value: $capacity, in: max(live.joined, 2)...99) {
                    Text("名额上限：\(capacity) 人")
                }
            } header: {
                Text(ActivityDetailCopy.hostManageCapacityTitle)
            } footer: {
                Text(ActivityDetailCopy.hostManageCapacityHint)
            }

            Section {
                DatePicker(
                    "开始时间",
                    selection: $date,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                TextField(ActivityDetailCopy.hostManageRescheduleNotePlaceholder, text: $notifyNote, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text(ActivityDetailCopy.hostManageRescheduleTitle)
            } footer: {
                Text(ActivityDetailCopy.hostManageRescheduleHint)
            }

            Section(ActivityDetailCopy.hostManageActionsTitle) {
                NavigationLink {
                    ActivityDetailView(activityID: live.id)
                } label: {
                    Label(ActivityDetailCopy.hostManageViewDetail, systemImage: "doc.text.magnifyingglass")
                }

                Button {
                    showContentEditor = true
                } label: {
                    Label("完善活动说明", systemImage: "square.and.pencil")
                }

                Button {
                    app.beginEditActivity(live.id)
                } label: {
                    Label(ActivityDetailCopy.hostManageEditBasics, systemImage: "pencil")
                }

                Button {
                    app.openActivityGroupChat(for: live)
                } label: {
                    Label("进入活动群", systemImage: "bubble.left.and.bubble.right")
                }

                if !live.isFree, !orders.isEmpty {
                    LabeledContent(ActivityDetailCopy.ordersTitle) {
                        Text("\(orders.count) 笔")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button("保存名额", systemImage: "person.2.badge.gearshape") {
                    model.updateCapacity(live.id, capacity: capacity)
                }
                .disabled(capacity == live.capacity)

                Button("确认改期", systemImage: "calendar.badge.clock") {
                    let trimmed = notifyNote.trimmingCharacters(in: .whitespacesAndNewlines)
                    app.rescheduleHostedActivity(
                        live.id,
                        to: date,
                        notifyNote: trimmed.isEmpty ? nil : trimmed
                    )
                }
                .disabled(date == live.date && notifyNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section {
                Button(ActivityDetailCopy.hostManageCancelActivity, role: .destructive) {
                    showCancelAlert = true
                }
            } footer: {
                Text(ActivityDetailCopy.hostManageCancelHint)
            }
        }
        .onAppear {
            capacity = live.capacity
            date = live.date
        }
        .onChange(of: live.capacity) { _, newValue in
            if capacity < newValue {
                capacity = newValue
            }
        }
        .onChange(of: live.date) { _, newValue in
            date = newValue
        }
        .confirmationDialog(
            ActivityDetailCopy.hostManageCancelAlertTitle,
            isPresented: $showCancelAlert,
            titleVisibility: .visible
        ) {
            Button(ActivityDetailCopy.hostManageCancelActivity, role: .destructive) {
                app.cancelHostedActivity(live.id)
                dismiss()
            }
            Button("保留活动", role: .cancel) {}
        } message: {
            Text(ActivityDetailCopy.hostManageCancelAlertMessage(title: live.title))
        }
    }
}

/// 我发起的行程卡片：带管理入口
struct ActivityHostedTripRow: View {
    let activity: Activity
    var zoomNamespace: Namespace.ID
    var onManage: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            ActivityZoomNavigationLink(
                activity: activity,
                namespace: zoomNamespace
            ) {
                ActivityDiscoverCard(
                    activity: activity,
                    isJoined: true,
                    enablesOpenTap: false
                )
            }

            Button(action: onManage) {
                Label(ActivityDetailCopy.hostManageTitle, systemImage: "slider.horizontal.3")
                    .frame(maxWidth: .infinity)
            }
            .activityPrimaryCTA(controlSize: .small)
        }
    }
}

struct ActivityDetailHostManageCard: View {
    let activity: Activity

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label("\(activity.joined)/\(activity.capacity)", systemImage: "person.2")
                Label(Formatters.activityEventTime(from: activity.date), systemImage: "calendar")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            NavigationLink {
                ActivityHostManageView(activityID: activity.id)
            } label: {
                Label(ActivityDetailCopy.hostManageTitle, systemImage: "slider.horizontal.3")
            }
        }
    }
}
