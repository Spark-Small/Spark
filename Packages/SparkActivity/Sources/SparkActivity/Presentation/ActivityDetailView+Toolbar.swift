// Module: SparkActivity — Activity detail toolbar menu.

import SparkDesignSystem
import SwiftUI

extension ActivityDetailView {
    @ViewBuilder
    func activityDetailToolbarMenu(activity: ActivityDetail) -> some View {
        Menu {
            ActivityShareFavoriteMenuItems(
                activityID: activity.id,
                title: activity.title,
                shareMessage: ActivityInviteURL.inviteCopyText(activity: activity)
            )

            Divider()

            if activity.showsHostManagement {
                Button {
                    showEditActivity = true
                } label: {
                    Label(
                        String(localized: "activity.host.edit", defaultValue: "编辑活动", comment: "Host edit"),
                        systemImage: "pencil"
                    )
                }
                Button {
                    showHostApproval = true
                } label: {
                    Label(
                        String(
                            localized: "activity.host.approval.entry",
                            defaultValue: "审批与协办",
                            comment: "Host approval entry"
                        ),
                        systemImage: "person.crop.circle.badge.checkmark"
                    )
                }
                Button {
                    showAnnounceSheet = true
                } label: {
                    Label(
                        String(
                            localized: "activity.host.announce",
                            defaultValue: "通知报名者",
                            comment: "Host announce"
                        ),
                        systemImage: "megaphone"
                    )
                }
                Button(role: .destructive) {
                    showCancelActivityConfirm = true
                } label: {
                    Label(
                        String(localized: "activity.host.cancel", defaultValue: "取消活动", comment: "Host cancel"),
                        systemImage: "xmark.circle"
                    )
                }
                Divider()
            }
            if activity.rsvpStatus == .going || activity.rsvpStatus == .maybe {
                Button(role: .destructive) {
                    showCancelAttendanceConfirm = true
                } label: {
                    Label(
                        String(
                            localized: "activity.detail.cancelAttendance",
                            defaultValue: "取消参加",
                            comment: "Cancel RSVP"
                        ),
                        systemImage: "person.crop.circle.badge.minus"
                    )
                }
                Divider()
            }
            Button {
                ActivityPasteboard.copy(ActivityInviteURL.inviteCopyText(activity: activity))
                viewModel.notifyInviteCopied()
            } label: {
                Label(
                    String(localized: "activity.copyInvite", defaultValue: "复制邀请文案", comment: "Copy invite"),
                    systemImage: "doc.on.doc"
                )
            }
            if activity.rsvpStatus != .host {
                if !createTemplateStore.isFavorited(activityID: activity.id) {
                    Button {
                        createTemplateStore.favorite(activity: activity)
                        templateFavoriteFeedback = String(
                            localized: "activity.create.template.favorite.success",
                            defaultValue: "已收藏为发起模版",
                            comment: "Template favorited"
                        )
                    } label: {
                        Label(
                            String(
                                localized: "activity.create.template.favorite.menu",
                                defaultValue: "收藏为发起模版",
                                comment: "Favorite as create template"
                            ),
                            systemImage: "square.and.arrow.down.on.square"
                        )
                    }
                }
                Button(role: .destructive) {
                    showReportSheet = true
                } label: {
                    Label(
                        String(localized: "activity.report.menu", defaultValue: "举报活动", comment: "Report"),
                        systemImage: "exclamationmark.bubble"
                    )
                }
            }
        } label: {
            Image(systemName: "ellipsis")
                .imageScale(.medium)
        }
        .buttonStyle(.plain)
        .id("\(activity.id)-\(favoriteStore.isFavorite(activityID: activity.id))")
        .accessibilityLabel(
            String(localized: "activity.detail.more.a11y", defaultValue: "更多操作", comment: "More a11y")
        )
    }
}
