//
//  BuddyInviteSheet.swift
//  坐标系
//

import SwiftUI

struct BuddyInviteSheet: View {
    let nickname: String
    let activities: [Activity]
    var onSent: ((Activity) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var model = BuddyInviteModel()

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            List(activities) { activity in
                Button {
                    model.selectedActivityID = activity.id
                } label: {
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

                        Spacer()

                        if model.selectedActivityID == activity.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
            .navigationTitle("邀约一起")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .top, spacing: 0) {
                Text("邀请 \(nickname) 一起参加")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PlatformMetrics.contentInset)
                    .padding(.vertical, PlatformMetrics.minContentGap)
                    .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("发送") {
                        if let id = model.selectedActivityID,
                           let selected = activities.first(where: { $0.id == id }) {
                            onSent?(selected)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!model.canSend)
                }
            }
        }
        .platformSheet(.browser)
    }
}

@MainActor
@Observable
private final class BuddyInviteModel {
    var selectedActivityID: Activity.ID?

    var canSend: Bool { selectedActivityID != nil }
}
