//
//  ActivityJoinSuccessSheet.swift
//  坐标系
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

    var navigationTitle: String {
        switch self {
        case .joined: ActivityCardStatus.joinSuccess
        case .published: "发布成功"
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

    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: context == .published ? "sparkles" : "checkmark.circle.fill")
                    .font(.largeTitle.weight(.semibold))
                    .platformSymbolStyle(.status(PlatformStatus.success))

                VStack {
                    Text(context.title)
                        .font(.title2.weight(.bold))
                    Text(context.subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(PlatformStatus.success)
                        .multilineTextAlignment(.center)
                    Text(activity.title)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                    Text(Formatters.activityEventTime(from: activity.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(activity.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack {
                    Button {
                        Task {
                            calendarMessage = await ActivityCalendar.add(activity, withReminders: true)
                        }
                    } label: {
                        Label(context.primaryCalendarLabel, systemImage: "calendar.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .activityPrimaryCTA(controlSize: .large)

                    Button {
                        onOpenGroup()
                        dismiss()
                    } label: {
                        Label(ActivityCardStatus.openGroupChat, systemImage: "bubble.left.and.bubble.right")
                            .frame(maxWidth: .infinity)
                    }
                    .activitySecondaryCTA(controlSize: .large)

                    if activity.isPast, let onWriteRecap {
                        Button {
                            onWriteRecap()
                            dismiss()
                        } label: {
                            Label("分享活动体验", systemImage: "square.and.pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .activitySecondaryCTA(controlSize: .large)
                    }
                }

                if let calendarMessage {
                    Text(calendarMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(PlatformMetrics.contentInset)
            .navigationTitle(context.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .platformSheet(.confirm)
    }
}
