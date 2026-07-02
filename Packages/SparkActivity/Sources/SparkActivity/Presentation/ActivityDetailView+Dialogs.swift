// Module: SparkActivity — Activity detail alerts and confirmation dialogs.

import SwiftUI

extension ActivityDetailView {
    @ViewBuilder
    func withDetailAlertsAndDialogs<Content: View>(_ content: Content) -> some View {
        content
            .alert(
                String(
                    localized: "activity.create.template.favorite.success",
                    defaultValue: "已收藏为发起模版",
                    comment: "Template favorited"
                ),
                isPresented: Binding(
                    get: { templateFavoriteFeedback != nil },
                    set: { if !$0 { templateFavoriteFeedback = nil } }
                )
            ) {
                Button(String(localized: "action.done", defaultValue: "完成", comment: "Done")) {
                    templateFavoriteFeedback = nil
                }
            }
            .confirmationDialog(
                String(
                    localized: "activity.detail.cancelAttendance.confirm.title",
                    defaultValue: "取消参加？",
                    comment: "Cancel attendance confirm title"
                ),
                isPresented: $showCancelAttendanceConfirm,
                titleVisibility: .visible
            ) {
                Button(
                    String(
                        localized: "activity.detail.cancelAttendance",
                        defaultValue: "取消参加",
                        comment: "Cancel RSVP"
                    ),
                    role: .destructive
                ) {
                    Task { await viewModel.cancelAttendance() }
                }
                Button(String(localized: "action.cancel", defaultValue: "返回", comment: "Dismiss"), role: .cancel) {}
            } message: {
                Text(cancelAttendanceConfirmMessage)
            }
            .confirmationDialog(
                String(
                    localized: "activity.calendar.confirm.title",
                    defaultValue: "添加到日历",
                    comment: "Calendar confirm title"
                ),
                isPresented: $showCalendarConfirm,
                titleVisibility: .visible
            ) {
                Button(
                    String(
                        localized: "activity.calendar.confirm.action",
                        defaultValue: "添加",
                        comment: "Calendar confirm action"
                    )
                ) {
                    Task { await viewModel.addToCalendar() }
                }
                Button(String(localized: "action.cancel", defaultValue: "取消", comment: "Dismiss"), role: .cancel) {}
            } message: {
                Text(calendarConfirmMessage)
            }
            .confirmationDialog(
                String(
                    localized: "activity.host.cancel.confirm.title",
                    defaultValue: "取消这场活动？",
                    comment: "Cancel confirm"
                ),
                isPresented: $showCancelActivityConfirm,
                titleVisibility: .visible
            ) {
                Button(
                    String(
                        localized: "activity.host.cancel.confirm.action",
                        defaultValue: "取消活动",
                        comment: "Cancel action"
                    ),
                    role: .destructive
                ) {
                    Task { await viewModel.cancelActivityAsHost() }
                }
                Button(String(localized: "action.cancel", defaultValue: "返回", comment: "Dismiss"), role: .cancel) {}
            } message: {
                Text(cancelActivityConfirmMessage)
            }
    }

    private var cancelAttendanceConfirmMessage: String {
        String(
            localized: "activity.detail.cancelAttendance.confirm.message",
            defaultValue: "你将不再显示为参加者，可随时重新报名。",
            comment: "Cancel attendance confirm message"
        )
    }

    private var calendarConfirmMessage: String {
        String(
            localized: "activity.calendar.confirm.message",
            defaultValue: "需要访问系统日历以保存活动时间，并可在日历 App 中查看提醒。",
            comment: "Calendar confirm message"
        )
    }

    private var cancelActivityConfirmMessage: String {
        String(
            localized: "activity.host.cancel.confirm.message",
            defaultValue: "报名者会看到活动已取消，群聊仍可查看历史消息。",
            comment: "Cancel confirm message"
        )
    }
}
