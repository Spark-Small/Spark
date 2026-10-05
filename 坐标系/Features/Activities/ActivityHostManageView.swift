//
//  ActivityHostManageView.swift
//  坐标系
//
//  发起人管理页：名额、改期、内容、取消活动。
//

import SwiftUI
import CoordinateModels

/// 详情共用的发起人管理页（Push 呈现）
struct ActivityHostManageView: View {
    let activityID: Activity.ID

    @Environment(ActivitiesModel.self) private var model
    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app
    @Environment(\.tabNavigationStateRef) private var navigation
    @Environment(\.dismiss) private var dismiss

    @State private var capacity: Int = 8
    @State private var date = Date()
    @State private var notifyNote = ""
    @State private var showCancelConfirm = false
    @State private var showRescheduleConfirm = false
    @State private var showContentEditor = false
    @State private var showOrders = false
    @State private var contentRevision = 0
    @State private var ordersRevision = 0

    private var live: Activity? {
        model.activity(id: activityID)
    }

    var body: some View {
        Group {
            if let live {
                manageForm(live)
            } else {
                ContentUnavailableView(ActivityDetailCopy.missingActivity, systemImage: "calendar")
                    .onAppear { dismiss() }
            }
        }
        .navigationTitle(ActivityDetailCopy.hostManageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showContentEditor) {
            if let live {
                ActivityDetailContentEditorSheet(activity: live) {
                    contentRevision += 1
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .sheet(isPresented: $showOrders) {
            ActivityOrdersSheet(
                activityID: activityID,
                onRefundCompleted: { ordersRevision += 1 }
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .confirmationDialog(
            ActivityDetailCopy.hostManageCancelAlertTitle,
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button(ActivityDetailCopy.hostManageCancelActivity, role: .destructive) {
                app.cancelHostedActivity(activityID)
                dismiss()
            }
            Button(ActivityDetailCopy.hostManageKeepActivity, role: .cancel) {}
        } message: {
            Text(
                ActivityDetailCopy.hostManageCancelAlertMessage(
                    title: live?.title ?? ActivityDetailCopy.hostManageFallbackTitle
                )
            )
        }
        .confirmationDialog(
            ActivityDetailCopy.hostManageRescheduleConfirmTitle,
            isPresented: $showRescheduleConfirm,
            titleVisibility: .visible
        ) {
            Button(ActivityDetailCopy.hostManageConfirmReschedule) {
                commitReschedule()
            }
            Button(ActivityDetailCopy.hostManageThinkAgain, role: .cancel) {}
        } message: {
            Text(ActivityDetailCopy.hostManageRescheduleConfirmMessage)
        }
    }

    @ViewBuilder
    private func manageForm(_ live: Activity) -> some View {
        let _ = contentRevision
        let _ = ordersRevision
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
                        Label(live.isFree ? ActivityCardStatus.free : live.fee, systemImage: "yensign.circle")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Section {
                LabeledContent(ActivityDetailCopy.hostManageCurrentSignup) {
                    Text("\(live.joined)/\(live.capacity) 人")
                }
                Stepper(value: $capacity, in: max(live.joined, 2)...99) {
                    Text(ActivityDetailCopy.hostManageCapacityLimit(capacity))
                }
            } header: {
                Text(ActivityDetailCopy.hostManageCapacityTitle)
            } footer: {
                Text(
                    capacityChanged(for: live)
                        ? ActivityDetailCopy.hostManageCapacityChangedHint
                        : ActivityDetailCopy.hostManageCapacityHint
                )
            }

            Section {
                DatePicker(
                    ActivityComposeCopy.startsLabel,
                    selection: $date,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                TextField(ActivityDetailCopy.hostManageRescheduleNotePlaceholder, text: $notifyNote, axis: .vertical)
                    .platformFormTextInput(.caption)
            } header: {
                Text(ActivityDetailCopy.hostManageRescheduleTitle)
            } footer: {
                Text(rescheduleFooter(for: live))
            }

            Section(ActivityDetailCopy.hostManageActionsTitle) {
                Button {
                    dismiss()
                } label: {
                    Label(ActivityDetailCopy.hostManageViewDetail, systemImage: "doc.text.magnifyingglass")
                }

                Button {
                    showContentEditor = true
                } label: {
                    Label(ActivityCardStatus.refineContent, systemImage: "square.and.pencil")
                }

                Button {
                    app.beginEditActivity(live.id)
                } label: {
                    Label(ActivityDetailCopy.hostManageEditBasics, systemImage: "pencil")
                }

                Button {
                    guard let route = app.prepareActivityGroupChatRoute(for: live) else { return }
                    if let navigation {
                        navigation.path.append(route)
                    } else {
                        app.openActivityGroupChat(for: live)
                    }
                } label: {
                    Label(ActivityDetailCopy.openGroupChat, systemImage: "bubble.left.and.bubble.right")
                }

                if !live.isFree, !orders.isEmpty {
                    Button {
                        showOrders = true
                    } label: {
                        LabeledContent(ActivityDetailCopy.ordersTitle) {
                            HStack(spacing: 4) {
                                Text("\(orders.count) 笔")
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("查看本场活动订单")
                }
            }

            Section {
                let capacityActive = capacityChanged(for: live)
                let dateChanged = dateChanged(for: live)
                let noteOnly = hasRescheduleNote && !dateChanged
                let rescheduleActive = dateChanged || noteOnly
                let rescheduleTitle = dateChanged
                    ? ActivityDetailCopy.hostManageConfirmReschedule
                    : ActivityDetailCopy.hostManageSendNoteOnly

                // HIG：同一区块只保留一个 prominent 主操作；改期影响成员，优先作为主确认。
                if capacityActive, !rescheduleActive {
                    Button(ActivityDetailCopy.hostManageSaveCapacity, systemImage: "person.2.badge.gearshape") {
                        model.updateCapacity(live.id, capacity: capacity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(ActivityDetailCopy.hostManageSaveCapacity, systemImage: "person.2.badge.gearshape") {
                        model.updateCapacity(live.id, capacity: capacity)
                    }
                    .disabled(!capacityActive)
                    .buttonStyle(.bordered)
                }

                if rescheduleActive {
                    Button(rescheduleTitle, systemImage: "calendar.badge.clock") {
                        showRescheduleConfirm = true
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(ActivityDetailCopy.hostManageConfirmReschedule, systemImage: "calendar.badge.clock") {
                        showRescheduleConfirm = true
                    }
                    .disabled(true)
                    .buttonStyle(.bordered)
                }
            } footer: {
                Text(commitActionsFooter(for: live))
            }

            Section {
                Button(ActivityDetailCopy.hostManageCancelActivity, role: .destructive) {
                    showCancelConfirm = true
                }
                .fontWeight(.semibold)
                .foregroundStyle(PlatformStatus.danger)
            } footer: {
                Text(ActivityDetailCopy.hostManageCancelHint)
            }
        }
        .platformTextInputScrollChrome()
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
    }

    private func capacityChanged(for live: Activity) -> Bool {
        capacity != live.capacity
    }

    private func dateChanged(for live: Activity) -> Bool {
        date != live.date
    }

    private var hasRescheduleNote: Bool {
        !notifyNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func rescheduleReady(for live: Activity) -> Bool {
        dateChanged(for: live) || hasRescheduleNote
    }

    private func commitReschedule() {
        let trimmed = notifyNote.trimmingCharacters(in: .whitespacesAndNewlines)
        app.rescheduleHostedActivity(
            activityID,
            to: date,
            notifyNote: trimmed.isEmpty ? nil : trimmed
        )
        notifyNote = ""
    }

    private func rescheduleFooter(for live: Activity) -> String {
        if rescheduleReady(for: live) {
            return ActivityDetailCopy.hostManageRescheduleHint
        }
        return ActivityDetailCopy.hostManageRescheduleUnchangedHint
    }

    private func commitActionsFooter(for live: Activity) -> String {
        switch (capacityChanged(for: live), rescheduleReady(for: live)) {
        case (true, true):
            return ActivityDetailCopy.hostManageCommitBothHint
        case (true, false):
            return ActivityDetailCopy.hostManageCapacityChangedHint
        case (false, true):
            return dateChanged(for: live)
                ? ActivityDetailCopy.hostManageRescheduleReadyHint
                : ActivityDetailCopy.hostManageNoteOnlyReadyHint
        case (false, false):
            return ActivityDetailCopy.hostManageCommitIdleHint
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
