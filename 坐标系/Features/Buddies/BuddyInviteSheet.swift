//
//  BuddyInviteSheet.swift
//  坐标系
//
//  邀约一起：单 Sheet 内选活动 → 确认发送（同 BuddyBookingSheet 步骤模式）。
//

import SwiftUI
import CoordinateModels

private enum BuddyInviteStep: Hashable {
    case select
    case confirm(Activity)
}

struct BuddyInviteSheet: View {
    let nickname: String
    let activities: [Activity]
    var onSent: ((Activity, String?) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var step: BuddyInviteStep = .select
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .select:
                    selectContent
                case .confirm(let activity):
                    confirmContent(activity)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if case .confirm = step {
                        Button(BuddyBookingFlowCopy.back) {
                            step = .select
                        }
                    } else {
                        Button(BuddyBookingFlowCopy.cancel) {
                            dismiss()
                        }
                    }
                }
                if case .confirm = step {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(BuddyBookingFlowCopy.inviteSend) {
                            sendInvite()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .platformSheet(.form)
    }

    private var navigationTitle: String {
        switch step {
        case .select:
            BuddyDetailCopy.invite
        case .confirm:
            BuddyBookingFlowCopy.inviteConfirmTitle
        }
    }

    @ViewBuilder
    private var selectContent: some View {
        if activities.isEmpty {
            ContentUnavailableView {
                Label(BuddyBookingFlowCopy.inviteEmptyTitle, systemImage: "calendar.badge.plus")
            } description: {
                Text(BuddyBookingFlowCopy.inviteEmptyBody)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                Section {
                    Text("邀请 \(nickname) 一起参加")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    ForEach(activities) { activity in
                        Button {
                            step = .confirm(activity)
                        } label: {
                            BuddyInviteActivityRow(activity: activity)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("选择活动")
                } footer: {
                    Text(BuddyBookingFlowCopy.inviteConfirmHint)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.visible)
        }
    }

    @ViewBuilder
    private func confirmContent(_ activity: Activity) -> some View {
        Form {
            Section {
                LabeledContent("邀请对象", value: nickname)
                LabeledContent("活动") {
                    Text(activity.title)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("时间") {
                    Text(Formatters.activityEventTime(from: activity.date))
                }
                LabeledContent("地点") {
                    Text(activity.location)
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("费用", value: activity.fee)
            } footer: {
                Text(BuddyBookingFlowCopy.inviteConfirmHint)
            }

            Section("留言") {
                TextField(
                    BuddyBookingFlowCopy.inviteNotePlaceholder,
                    text: $note,
                    axis: .vertical
                )
                .lineLimit(3...5)
            }
        }
    }

    private func sendInvite() {
        guard case .confirm(let activity) = step else { return }
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        onSent?(activity, trimmed.isEmpty ? nil : trimmed)
        dismiss()
    }
}

private struct BuddyInviteActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: PlatformMetrics.railCardSpacing) {
            Image(systemName: activity.category.systemImage)
                .foregroundStyle(.tint)
                .frame(width: PlatformMetrics.railCardSpacing * 2)

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(activity.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                Text("\(Formatters.activityDate.string(from: activity.date)) · \(activity.location)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
        .contentShape(Rectangle())
    }
}
