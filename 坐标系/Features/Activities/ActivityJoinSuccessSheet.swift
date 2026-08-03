//
//  ActivityJoinSuccessSheet.swift
//  坐标系
//
//  参加 / 发布成功半屏：对齐系统确认 Sheet（符号 + 文案居中，底栏系统按钮）。
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
        case .joined: "已自动加入活动群，重要通知将同步推送"
        case .published: "活动群已创建，可在消息里通知已参加成员"
        }
    }

    var primaryCalendarLabel: String {
        switch self {
        case .joined: "添加日历提醒"
        case .published: "添加开场提醒"
        }
    }

    var symbolName: String {
        switch self {
        case .joined: "checkmark.circle.fill"
        case .published: "sparkles"
        }
    }
}

/// 参加 / 发布成功闭环：日历 + 进群
struct ActivityJoinSuccessSheet: View {
    let activity: Activity
    var context: ActivitySuccessContext = .joined
    var onOpenGroup: () -> Void
    var onWriteRecap: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var calendarMessage: String?
    @State private var didAppear = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer(minLength: 12)

                hero

                Spacer(minLength: 16)

                actions
            }
            .padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.bottom, 8)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { didAppear = true }
            .sensoryFeedback(.success, trigger: didAppear) { _, appeared in appeared }
        }
        .platformSheet(.confirm)
    }

    private var hero: some View {
        VStack(spacing: PlatformMetrics.sectionSpacing) {
            Image(systemName: context.symbolName)
                .font(.system(size: 44))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(PlatformStatus.success)

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
            }
            .padding(.horizontal, PlatformMetrics.minContentGap)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var publishedMeta: some View {
        VStack(spacing: 4) {
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

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    calendarMessage = await ActivityCalendar.add(activity, withReminders: true)
                }
            } label: {
                Label(context.primaryCalendarLabel, systemImage: "calendar.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                onOpenGroup()
                dismiss()
            } label: {
                Label(ActivityCardStatus.openGroupChat, systemImage: "bubble.left.and.bubble.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            if activity.isPast, let onWriteRecap {
                Button {
                    onWriteRecap()
                    dismiss()
                } label: {
                    Label("分享活动体验", systemImage: "square.and.pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            if let calendarMessage {
                Text(calendarMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
