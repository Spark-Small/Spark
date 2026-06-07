// Module: SparkActivity — Host RSVP / co-host approval queue.

import SparkDesignSystem
import SwiftUI

struct ActivityHostApprovalView: View {
    @Bindable var viewModel: ActivityDetailViewModel
    let activity: ActivityDetail

    private var pendingAttendees: [ActivityAttendee] {
        activity.attendees.filter { attendee in
            !attendee.isHost && (attendee.rsvpStatus == .waitlisted || attendee.rsvpStatus == .invited)
        }
    }

    var body: some View {
        List {
            if pendingAttendees.isEmpty {
                ContentUnavailableView(
                    String(
                        localized: "activity.host.approval.empty.title",
                        defaultValue: "暂无待审批",
                        comment: "No pending approvals"
                    ),
                    systemImage: "person.crop.circle.badge.checkmark",
                    description: Text(
                        String(
                            localized: "activity.host.approval.empty.subtitle",
                            defaultValue: "候补与待回复的报名会显示在这里",
                            comment: "Approval empty hint"
                        )
                    )
                )
            } else {
                Section {
                    ForEach(pendingAttendees) { attendee in
                        attendeeCard(attendee)
                            .sparkFlatTabListRow()
                    }
                } header: {
                    Text(
                        String(
                            localized: "activity.host.approval.section",
                            defaultValue: "待处理报名",
                            comment: "Approval section"
                        )
                    )
                }
            }
        }
        .sparkFlatTabListStyle()
        .navigationTitle(
            String(
                localized: "activity.host.approval.title",
                defaultValue: "审批与协办",
                comment: "Host approval title"
            )
        )
        .navigationBarTitleDisplayMode(.inline)
        .disabled(viewModel.isPerformingHostAction)
        .overlay {
            if viewModel.isPerformingHostAction {
                ProgressView()
                    .sparkLoadingAccessibilityLabel(
                        String(
                            localized: "activity.host.approval.loading.a11y",
                            defaultValue: "正在处理",
                            comment: "Host approval loading"
                        )
                    )
            }
        }
    }

    private func attendeeCard(_ attendee: ActivityAttendee) -> some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.sectionVerticalPadding) {
            HStack {
                Text(attendee.displayName)
                    .font(.headline)
                Spacer()
                if let status = attendee.rsvpStatus {
                    Text(status.localizedLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            if attendee.isCoHost {
                Label(
                    String(
                        localized: "activity.host.cohost.badge",
                        defaultValue: "协办",
                        comment: "Co-host badge"
                    ),
                    systemImage: "person.2.fill"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            HStack(spacing: SparkLayoutMetrics.compactVerticalPadding) {
                Button(
                    String(
                        localized: "activity.host.approve",
                        defaultValue: "通过",
                        comment: "Approve RSVP"
                    )
                ) {
                    Task { await viewModel.approveAttendee(attendee.id) }
                }
                .buttonStyle(.borderedProminent)
                .sparkMinimumTouchTarget()

                Button(
                    String(
                        localized: "activity.host.deny",
                        defaultValue: "拒绝",
                        comment: "Deny RSVP"
                    ),
                    role: .destructive
                ) {
                    Task { await viewModel.denyAttendee(attendee.id) }
                }
                .buttonStyle(.bordered)
                .sparkMinimumTouchTarget()
            }
            Button(
                attendee.isCoHost
                    ? String(
                        localized: "activity.host.cohost.remove",
                        defaultValue: "取消协办",
                        comment: "Remove co-host"
                    )
                    : String(
                        localized: "activity.host.cohost.add",
                        defaultValue: "设为协办",
                        comment: "Add co-host"
                    )
            ) {
                Task { await viewModel.setCoHost(attendee.id, isCoHost: !attendee.isCoHost) }
            }
            .font(.subheadline)
            .buttonStyle(.sparkPressable)
            .sparkMinimumTouchTarget()
        }
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
    }
}

#Preview {
    NavigationStack {
        if let activity = MockActivityCatalog.detail(id: "act_3") {
            ActivityHostApprovalView(
                viewModel: ActivityDetailViewModel(activityID: "act_3", repository: MockActivityFeedRepository()),
                activity: activity
            )
        }
    }
}
