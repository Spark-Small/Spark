// Module: SparkActivity — Host roster row actions (approve / cohost).

import SwiftUI

struct ActivityHostRosterRowActions: View {
    let attendee: ActivityAttendee
    let viewModel: ActivityDetailViewModel

    var body: some View {
        if attendee.isCohost {
            Text(
                String(
                    localized: "activity.attendee.cohost",
                    defaultValue: "协办",
                    comment: "Co-host badge"
                )
            )
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
        } else if let status = attendee.rsvpStatus {
            Text(status.localizedLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            if status == .pending || status == .waitlisted {
                Button(
                    String(
                        localized: "activity.host.review.approve",
                        defaultValue: "通过",
                        comment: "Approve attendee"
                    )
                ) {
                    Task { await viewModel.reviewAttendee(attendee.id, decision: .approve) }
                }
                .font(.caption)
                Button(
                    String(
                        localized: "activity.host.review.reject",
                        defaultValue: "拒绝",
                        comment: "Reject attendee"
                    ),
                    role: .destructive
                ) {
                    Task { await viewModel.reviewAttendee(attendee.id, decision: .reject) }
                }
                .font(.caption)
            }
            if status == .waitlisted {
                Button(
                    String(
                        localized: "activity.host.promote",
                        defaultValue: "提升",
                        comment: "Promote waitlist"
                    )
                ) {
                    Task { await viewModel.promoteWaitlistedAttendee(attendee.id) }
                }
                .font(.caption)
            }
            if status == .going {
                Button(
                    String(
                        localized: "activity.host.assignCohost",
                        defaultValue: "设协办",
                        comment: "Assign co-host"
                    )
                ) {
                    Task { await viewModel.assignCohost(to: attendee.id) }
                }
                .font(.caption)
            }
        }
    }
}
