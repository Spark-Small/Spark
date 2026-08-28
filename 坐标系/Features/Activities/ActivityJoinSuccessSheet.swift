//
//  ActivityJoinSuccessSheet.swift
//  坐标系
//
//  参加 / 发布成功半屏：SVG 插画 + 下一步分流。
//  参加成功：左上日历、右上关闭；「进群打招呼」次要、「找个搭子」主色。
//

import SwiftUI

enum ActivitySuccessContext {
    case joined
    case published

    var title: String {
        switch self {
        case .joined: ActivityCardStatus.joinSuccess
        case .published: "活动已发布"
        }
    }

    var subtitle: String {
        switch self {
        case .joined:
            "已自动加入活动群，点击左上角按钮加入日历提醒吧，希望拥有一段美好的活动旅程"
        case .published:
            "活动群已创建，可在消息里通知已参加成员"
        }
    }

    var primaryCalendarLabel: String {
        switch self {
        case .joined: ActivityDetailCopy.calendarAction
        case .published: "添加开场提醒"
        }
    }

    var openGroupLabel: String {
        ActivityCardStatus.openGroupChat
    }

    var illustrationName: String {
        switch self {
        case .joined: "ActivityJoinSuccess"
        case .published: "ActivityPublishSuccess"
        }
    }
}

/// 参加 / 发布成功闭环
struct ActivityJoinSuccessSheet: View {
    let activity: Activity
    var context: ActivitySuccessContext = .joined
    var onOpenGroup: () -> Void
    var onWriteRecap: (() -> Void)?

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var calendarMessage: String?
    @State private var showCalendarAccessAlert = false
    @State private var didAppear = false
    @State private var isOnCalendar = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    hero
                        .padding(.top, 12)

                    actions
                        .padding(.top, 16)
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
                .padding(.bottom, PlatformMetrics.minContentGap)
            }
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear {
                didAppear = true
                isOnCalendar = ActivityCalendar.isScheduled(activityID: activity.id)
            }
            .sensoryFeedback(.success, trigger: didAppear) { _, appeared in appeared }
        }
        .platformSheet(context == .joined ? .browser : .confirm)
        .activityCalendarAccessAlert(isPresented: $showCalendarAccessAlert)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if context == .joined {
            ToolbarItem(placement: .topBarLeading) {
                ActivityDetailControls.CalendarToolbarButton(isScheduled: isOnCalendar) {
                    Task { await toggleCalendarReminder() }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("关闭")
            }
        } else {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { dismiss() }
                    .fontWeight(.semibold)
            }
        }
    }

    private var hero: some View {
        VStack(spacing: PlatformMetrics.sectionSpacing) {
            Image(context.illustrationName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .frame(height: 120)
                .accessibilityHidden(true)

            VStack(spacing: PlatformMetrics.detailMicroSpacing) {
                Text(context.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(context.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if context == .published {
                    publishedMeta
                }

                if let calendarMessage {
                    Text(calendarMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            .padding(.horizontal, PlatformMetrics.minContentGap)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var publishedMeta: some View {
        VStack(spacing: PlatformMetrics.hairlineSpacing) {
            Text(activity.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(Formatters.activityEventTime(from: activity.date))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(activity.location)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, PlatformMetrics.detailMicroSpacing)
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: PlatformMetrics.cardFooterSpacing) {
            if context == .published {
                publishedActions
            } else {
                joinedActions
            }

            if activity.isPast, let onWriteRecap {
                Button {
                    dismissThen(onWriteRecap)
                } label: {
                    Label("分享活动体验", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var publishedActions: some View {
        Group {
            Button {
                Task { await toggleCalendarReminder() }
            } label: {
                Label(
                    isOnCalendar ? ActivityDetailCopy.calendarRemoveAction : context.primaryCalendarLabel,
                    systemImage: ActivityCalendar.Symbol.systemName(isScheduled: isOnCalendar)
                )
                .frame(maxWidth: .infinity)
            }
            .modifier(ActivitySuccessCalendarButtonStyle(isOnCalendar: isOnCalendar))
            .controlSize(.large)

            Button {
                dismissThen(onOpenGroup)
            } label: {
                Label(context.openGroupLabel, systemImage: "bubble.left.and.bubble.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    private var joinedActions: some View {
        Group {
            Button {
                dismissThen(onOpenGroup)
            } label: {
                Label(context.openGroupLabel, systemImage: "bubble.left.and.bubble.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button {
                dismissThen { app.selectedTab = .buddies }
            } label: {
                Label("找个搭子", systemImage: "person.2")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("去搭子页找同好，可约同场或相关兴趣")
        }
    }

    private func dismissThen(_ action: @escaping () -> Void) {
        dismiss()
        DispatchQueue.main.async {
            action()
        }
    }

    @MainActor
    private func toggleCalendarReminder() async {
        switch await ActivityCalendar.toggle(activity, withReminders: true) {
        case .added(let withReminders):
            isOnCalendar = true
            calendarMessage = ActivityCalendar.successMessage(withReminders: withReminders)
        case .removed:
            isOnCalendar = false
            calendarMessage = ActivityCalendar.removedMessage
        case .accessDenied:
            showCalendarAccessAlert = true
        case .failed:
            calendarMessage = isOnCalendar
                ? ActivityDetailCopy.calendarRemoveFailedMessage
                : ActivityDetailCopy.calendarFailedMessage
        }
    }
}

private struct ActivitySuccessCalendarButtonStyle: ViewModifier {
    let isOnCalendar: Bool

    func body(content: Content) -> some View {
        if isOnCalendar {
            content.buttonStyle(.bordered)
        } else {
            content.buttonStyle(.borderedProminent)
        }
    }
}
