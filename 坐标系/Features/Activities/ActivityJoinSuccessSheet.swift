//
//  ActivityJoinSuccessSheet.swift
//  坐标系
//
//  参加 / 发布成功半屏：庆祝 + 唯一入口「我的行程」。
//

import SwiftUI
import CoordinateModels

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
            "开场前可在「我的行程」完成准备"
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
    var onOpenJourney: (() -> Void)?
    var onOpenGroup: (() -> Void)?

    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var calendarMessage: String?
    @State private var showCalendarAccessAlert = false
    @State private var didAppear = false
    @State private var isOnCalendar = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: PlatformMetrics.sectionSpacing) {
                    hero

                    if context == .joined {
                        joinedActions
                    } else {
                        publishedActions
                    }
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
                .padding(.bottom, PlatformMetrics.minContentGap)
            }
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                didAppear = true
                isOnCalendar = ActivityCalendar.isScheduled(activityID: activity.id)
                Task {
                    await PermissionLaunchPrompts.requestNotificationWhenJoiningIfNeeded()
                }
            }
            .sensoryFeedback(.success, trigger: didAppear) { _, appeared in appeared }
        }
        .platformSheet(context == .joined ? .browser : .confirm)
        .activityCalendarAccessAlert(isPresented: $showCalendarAccessAlert)
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

                if context == .joined {
                    joinedMeta
                } else if context == .published {
                    publishedMeta
                }

                if let calendarMessage {
                    Text(calendarMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var joinedMeta: some View {
        VStack(spacing: PlatformMetrics.hairlineSpacing) {
            Text(activity.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("\(Formatters.activityEventTime(from: activity.date)) · \(activity.location)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text(ActivityCardStatus.joinSuccessGroupHint)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, PlatformMetrics.hairlineSpacing)
        }
        .padding(.top, PlatformMetrics.detailMicroSpacing)
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

    private var joinedActions: some View {
        VStack(spacing: PlatformMetrics.cardFooterSpacing) {
            Button {
                dismissThen { onOpenJourney?() }
            } label: {
                Label(ActivityDetailCopy.credentialViewAction, systemImage: "ticket.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                Task { await toggleCalendarReminder() }
            } label: {
                Label(
                    isOnCalendar ? ActivityDetailCopy.calendarRemoveAction : ActivityDetailCopy.calendarAction,
                    systemImage: ActivityCalendar.Symbol.systemName(isScheduled: isOnCalendar)
                )
                .frame(maxWidth: .infinity)
            }
            .modifier(ActivitySuccessCalendarButtonStyle(isOnCalendar: isOnCalendar))
            .controlSize(.large)
            .disabled(isOnCalendar)

            Button("还没找到同行？找个搭子") {
                dismissThen { app.selectedTab = .buddies }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, PlatformMetrics.hairlineSpacing)
        }
    }

    private var publishedActions: some View {
        VStack(spacing: PlatformMetrics.cardFooterSpacing) {
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
                dismissThen { onOpenGroup?() }
            } label: {
                Label(context.openGroupLabel, systemImage: "bubble.left.and.bubble.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
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
            content.buttonStyle(.bordered)
        }
    }
}
