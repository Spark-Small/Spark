// Module: SparkMessages — Action item card components.

import SwiftUI

struct ActionCardContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16)
    }
}

struct ActivityInviteActionCard: View {
    let invite: ActivityInvite
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        ActionCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    String(localized: "messages.action.invite", defaultValue: "活动邀请", comment: "Invite"),
                    systemImage: "figure.hiking"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)

                Text(invite.activity.title)
                    .font(.headline)
                Text(activityMeta)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(inviterLine)
                    .font(.subheadline)

                HStack(spacing: 12) {
                    Button(
                        String(localized: "messages.action.accept", defaultValue: "报名参加", comment: "Accept invite"),
                        action: onAccept
                    )
                    .buttonStyle(.borderedProminent)

                    Button(
                        String(localized: "messages.action.decline", defaultValue: "暂时不了", comment: "Decline invite"),
                        action: onDecline
                    )
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var activityMeta: String {
        "\(invite.activity.formattedDateShort) · \(memberCount)"
    }

    private var memberCount: String {
        let format = String(
            localized: "messages.group.members.format",
            defaultValue: "%lld 人",
            comment: "Member count"
        )
        return String(format: format, locale: .current, invite.activity.attendeeCount)
    }

    private var inviterLine: String {
        let format = String(
            localized: "messages.action.inviter.format",
            defaultValue: "%@ 邀请你参加",
            comment: "Inviter; %@ is name"
        )
        return String(format: format, locale: .current, invite.inviter.displayName)
    }
}

struct ActivityChangeAlertCard: View {
    let change: ActivityChange
    let onViewActivity: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ActionCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    String(localized: "messages.action.change", defaultValue: "活动变更", comment: "Change alert"),
                    systemImage: "exclamationmark.triangle.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)

                Text(changeTitle)
                    .font(.headline)
                Text(hostLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button(
                        String(localized: "messages.action.viewSchedule", defaultValue: "查看新安排", comment: "View schedule"),
                        action: onViewActivity
                    )
                    .buttonStyle(.borderedProminent)

                    Button(
                        String(localized: "messages.action.dismiss", defaultValue: "知道了", comment: "Dismiss"),
                        action: onDismiss
                    )
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var changeTitle: String {
        switch change.kind {
        case .rescheduled:
            let format = String(
                localized: "messages.action.rescheduled.format",
                defaultValue: "「%@」已改期",
                comment: "Rescheduled; %@ is title"
            )
            return String(format: format, locale: .current, change.activity.title)
        case .cancelled:
            let format = String(
                localized: "messages.action.cancelled.format",
                defaultValue: "「%@」已取消",
                comment: "Cancelled; %@ is title"
            )
            return String(format: format, locale: .current, change.activity.title)
        }
    }

    private var hostLine: String {
        let format = String(
            localized: "messages.action.host.format",
            defaultValue: "主办：%@ · %@",
            comment: "Host line; %1$@ host, %2$@ previous"
        )
        return String(format: format, locale: .current, change.hostName, change.previousScheduleLine)
    }
}

struct WaitlistPromotedCard: View {
    let activity: InboxActivitySummary
    let onViewActivity: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ActionCardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Label(
                    String(localized: "messages.action.waitlist", defaultValue: "候补提升", comment: "Waitlist promoted"),
                    systemImage: "arrow.up.circle.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.accentColor)

                Text(
                    String(
                        localized: "messages.action.waitlist.title",
                        defaultValue: "你已获得名额",
                        comment: "Waitlist promoted title"
                    )
                )
                .font(.headline)
                Text(activity.title)
                    .font(.subheadline)
                Text(activity.formattedDateShort)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button(
                        String(localized: "messages.activity.viewDetail", defaultValue: "查看详情", comment: "View detail"),
                        action: onViewActivity
                    )
                    .buttonStyle(.borderedProminent)

                    Button(
                        String(localized: "messages.action.dismiss", defaultValue: "知道了", comment: "Dismiss"),
                        action: onDismiss
                    )
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}
