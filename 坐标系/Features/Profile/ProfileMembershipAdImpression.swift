//
//  ProfileMembershipAdImpression.swift
//  坐标系
//
//  会员广告位：对齐 AdAttributionKit `AdContentView` 的嵌入式内容视图。
//

import SwiftUI
import CoordinateModels

/// 会员入口：与 `ProfileFormGatedRow` 同形态；`onDisappear` 记 view-through。
struct ProfileMembershipAdContentView: View {
    let isActive: Bool
    var onTap: () -> Void

    @Environment(MembershipAdImpressionStore.self) private var adImpression
    @State private var appearedAt: Date?
    @State private var didRecordView = false
    @State private var isHandlingTap = false
    @State private var tapCount = 0

    private var title: String {
        isActive ? ProfileDashboardCopy.membershipCenter : ProfileDashboardCopy.membershipOpen
    }

    private var systemImage: String {
        isActive ? "checkmark.seal.fill" : "crown.fill"
    }

    var body: some View {
        ProfileFormGatedRow(
            title: title,
            systemImage: systemImage,
            action: handleMembershipTapped
        )
        .opacity(isHandlingTap ? 0.72 : 1)
        .onAppear { appearedAt = .now }
        .onDisappear { handleMembershipDisappeared() }
        .sensoryFeedback(.selection, trigger: tapCount)
        .accessibilityAddTraits(.isButton)
    }

    private func handleMembershipDisappeared() {
        guard adImpression.shouldRecordView(
            appearedAt: appearedAt,
            alreadyRecorded: didRecordView
        ) else { return }

        Task {
            do {
                try await adImpression.handleView(isActive: isActive)
                didRecordView = true
            } catch {
                #if DEBUG
                assertionFailure("Failed to end view through impression: \(error)")
                #endif
            }
        }
    }

    private func handleMembershipTapped() {
        guard !isHandlingTap else { return }
        isHandlingTap = true
        tapCount &+= 1

        Task {
            defer { isHandlingTap = false }
            do {
                try await adImpression.handleTap(isActive: isActive)
            } catch {
                #if DEBUG
                assertionFailure("Failed to perform click through impression: \(error)")
                #endif
            }
            onTap()
        }
    }
}
