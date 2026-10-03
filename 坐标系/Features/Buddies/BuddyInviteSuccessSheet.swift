//
//  BuddyInviteSuccessSheet.swift
//  坐标系
//
//  邀约发送成功 Sheet。
//

import SwiftUI
import CoordinateModels

struct BuddyInviteSuccessSheet: View {
    let record: BuddyInviteRecord
    var activitySubtitle: String?
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
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
            .padding(.bottom, PlatformMetrics.minContentGap)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(BuddyBookingFlowCopy.done) {
                        onDone()
                        dismiss()
                    }
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
            Image(systemName: "paperplane.circle.fill")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(PlatformStatus.success)

            VStack(spacing: PlatformMetrics.detailMicroSpacing) {
                Text(BuddyBookingFlowCopy.inviteSuccessTitle)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)

                Text(BuddyBookingFlowCopy.inviteSuccessSubtitle(record.nickname))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: PlatformMetrics.hairlineSpacing) {
                    Text(record.activityTitle)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    if let activitySubtitle {
                        Text(activitySubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, PlatformMetrics.detailMicroSpacing)
            }
            .padding(.horizontal, PlatformMetrics.minContentGap)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var actions: some View {
        VStack(spacing: PlatformMetrics.cardFooterSpacing) {
            Button {
                onDone()
                dismiss()
            } label: {
                Label(BuddyBookingFlowCopy.done, systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
    }
}
