//
//  ActivityJoinSuccessSheet.swift
//  坐标系
//
//  参加 / 发布成功半屏：单一主后续（参加→行程；发布→群）；日历/群为次要。
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
            "下一步：到我的行程，查看凭证与准备清单"
        case .published:
            "建议在管理页完善行程与费用说明；活动群已创建"
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
                    Button(ActivityDetailCopy.peopleSheetDone) { dismiss() }
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
                .frame(
                    maxWidth: PlatformMetrics.journeyContentMaxWidth
                        * PlatformMetrics.successIllustrationMaxWidthFactor
                )
                .aspectRatio(PlatformMetrics.successIllustrationAspectRatio, contentMode: .fit)
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

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Label("行程里完成准备清单与查看凭证", systemImage: "checklist")
                Label("日历提醒与活动群为辅助入口", systemImage: "calendar")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, PlatformMetrics.hairlineSpacing)
            .accessibilityElement(children: .combine)
        }
        .padding(.top, PlatformMetrics.detailMicroSpacing)
    }

    private var publishedMeta: some View {
        VStack(spacing: PlatformMetrics.hairlineSpacing) {
            Text(activity.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("\(Formatters.activityEventTime(from: activity.date)) · \(activity.location)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Label("在管理页完善行程、费用与须知", systemImage: "square.and.pencil")
                Label("打开活动群，同步集合与变更", systemImage: "bubble.left.and.bubble.right")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, PlatformMetrics.hairlineSpacing)
            .accessibilityElement(children: .combine)
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
            .buttonStyle(.bordered)
            .controlSize(.large)

            if onOpenGroup != nil {
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
    }

    private var publishedActions: some View {
        VStack(spacing: PlatformMetrics.cardFooterSpacing) {
            Button {
                dismissThen { onOpenGroup?() }
            } label: {
                Label(context.openGroupLabel, systemImage: "bubble.left.and.bubble.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                Task { await toggleCalendarReminder() }
            } label: {
                Label(
                    isOnCalendar ? ActivityDetailCopy.calendarRemoveAction : context.primaryCalendarLabel,
                    systemImage: ActivityCalendar.Symbol.systemName(isScheduled: isOnCalendar)
                )
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
