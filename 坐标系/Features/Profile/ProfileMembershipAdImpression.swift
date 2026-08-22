//
//  ProfileMembershipAdImpression.swift
//  坐标系
//
//  会员广告位：本地曝光账本 + 对齐 AdAttributionKit `AdContentView` 的嵌入式内容视图。
//

import Foundation
import SwiftUI

/// 本地演示用会员「广告位」曝光与点击账本。
@MainActor
enum ProfileMembershipAdImpression {
    private static let viewCountKey = "profile.membership.ad.viewCount"
    private static let tapCountKey = "profile.membership.ad.tapCount"
    private static let lastViewAtKey = "profile.membership.ad.lastViewAt"
    private static let lastTapAtKey = "profile.membership.ad.lastTapAt"

    /// 最短停留后再记一次 view-through（秒），避免闪现误计。
    static let minimumViewDuration: TimeInterval = 1

    static var viewCount: Int {
        UserDefaults.standard.integer(forKey: viewCountKey)
    }

    static var tapCount: Int {
        UserDefaults.standard.integer(forKey: tapCountKey)
    }

    /// 对应 `AppImpression.handleView()`：结束展示时记录 view-through。
    static func handleView(isActive: Bool) async throws {
        let defaults = UserDefaults.standard
        defaults.set(viewCount + 1, forKey: viewCountKey)
        defaults.set(Date().timeIntervalSince1970, forKey: lastViewAtKey)
        defaults.set(isActive, forKey: "profile.membership.ad.lastViewWasMember")
    }

    /// 对应 `AppImpression.handleTap()`：有效点击后记录 click-through。
    static func handleTap(isActive: Bool) async throws {
        let defaults = UserDefaults.standard
        defaults.set(tapCount + 1, forKey: tapCountKey)
        defaults.set(Date().timeIntervalSince1970, forKey: lastTapAtKey)
        defaults.set(isActive, forKey: "profile.membership.ad.lastTapWasMember")
    }

    /// 是否应记曝光：需满足最短可见时长，且本轮会话尚未记过。
    static func shouldRecordView(
        appearedAt: Date?,
        alreadyRecorded: Bool
    ) -> Bool {
        guard !alreadyRecorded, let appearedAt else { return false }
        return Date().timeIntervalSince(appearedAt) >= minimumViewDuration
    }

    #if DEBUG
    static func resetForDebug() {
        let defaults = UserDefaults.standard
        [
            viewCountKey, tapCountKey, lastViewAtKey, lastTapAtKey,
            "profile.membership.ad.lastViewWasMember",
            "profile.membership.ad.lastTapWasMember"
        ].forEach { defaults.removeObject(forKey: $0) }
    }
    #endif
}

// MARK: - Ad content view

/// 自定义会员条：嵌入 List 内容流（非导航吸顶），`onTap` / `onDisappear` 对应 click / view-through。
struct ProfileMembershipAdContentView: View {
    let isActive: Bool
    var onTap: () -> Void

    @State private var appearedAt: Date?
    @State private var didRecordView = false
    @State private var isHandlingTap = false
    @State private var tapCount = 0

    private var title: String {
        isActive ? ProfileDashboardCopy.membershipCenter : ProfileDashboardCopy.membershipOpen
    }

    var body: some View {
        HStack {
            Label(title, systemImage: isActive ? "checkmark.seal.fill" : "crown.fill")
                .symbolRenderingMode(.multicolor)
                .foregroundStyle(.primary)
                .platformContentSymbolStyle()

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .opacity(isHandlingTap ? 0.72 : 1)
        .onAppear { appearedAt = .now }
        .onTapGesture { handleMembershipTapped() }
        .onDisappear { handleMembershipDisappeared() }
        .sensoryFeedback(.selection, trigger: tapCount)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(title)
        .accessibilityAction { handleMembershipTapped() }
    }

    private func handleMembershipDisappeared() {
        guard ProfileMembershipAdImpression.shouldRecordView(
            appearedAt: appearedAt,
            alreadyRecorded: didRecordView
        ) else { return }

        Task {
            do {
                try await ProfileMembershipAdImpression.handleView(isActive: isActive)
                didRecordView = true
            } catch {
                print("Failed to end view through impression: \(error).")
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
                try await ProfileMembershipAdImpression.handleTap(isActive: isActive)
            } catch {
                print("Failed to perform click through impression: \(error).")
            }
            onTap()
        }
    }
}
