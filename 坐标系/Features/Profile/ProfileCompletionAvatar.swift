//
//  ProfileCompletionAvatar.swift
//  坐标系
//
//  「我的」头像 + 环形资料完整度（从 EditProfileSheet 拆出）。
//

import SwiftUI
import UIKit
import CoordinateModels

struct ProfileAvatarView: View {
    enum Style {
        /// 普通列表行：`ImageProperties.standardDimension`，无完整度环。
        case listRow
        /// 「我的」根身份头：账号式大头像 + 完整度环。
        case accountHeader
        /// 设置·账号等资料块：中等头像 + 完整度环。
        case detail
    }

    let user: AppUser
    var style: Style = .detail

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// 兼容旧调用：`listRowSized: true` → `.listRow`。
    init(user: AppUser, listRowSized: Bool = false) {
        self.user = user
        self.style = listRowSized ? .listRow : .detail
    }

    init(user: AppUser, style: Style) {
        self.user = user
        self.style = style
    }

    var body: some View {
        switch style {
        case .listRow:
            PlatformListAvatarView(
                name: user.name,
                photo: user.localAvatarImage,
                side: PlatformConversationListRow.imageSide
            )
            .accessibilityLabel("头像")
            .accessibilityValue(completionAccessibilityValue)
        case .accountHeader, .detail:
            ProfileCompletionAvatar(
                name: user.name,
                photo: user.localAvatarImage,
                side: style == .accountHeader
                    ? dynamicTypeSize.accountHeaderAvatarSide
                    : dynamicTypeSize.detailRelatedThumbSide,
                completion: ProfileCompletion.ratio(for: user)
            )
        }
    }

    private var completionAccessibilityValue: String {
        let percent = Int((ProfileCompletion.ratio(for: user) * 100).rounded())
        return "资料完整度 \(percent)%"
    }

}

struct ProfileCompletionAvatar: View {
    var name: String
    var photo: UIImage?
    var side: CGFloat
    var completion: Double?

    private var ringStart: CGFloat { PlatformMetrics.profileCompletionRingTrimStart }
    private var ringEnd: CGFloat { PlatformMetrics.profileCompletionRingTrimEnd }

    private var normalizedCompletion: Double? {
        completion.map { min(max($0, 0), 1) }
    }

    private var percentage: Int? {
        normalizedCompletion.map { Int(($0 * 100).rounded()) }
    }

    private var ringLineWidth: CGFloat { PlatformMetrics.avatarBadgeStroke }
    private var progressLineWidth: CGFloat { PlatformMetrics.avatarBadgeStroke * 2 }
    private var avatarInset: CGFloat { PlatformMetrics.avatarBadgeStroke * 3 }

    var body: some View {
        ZStack {
            if let normalizedCompletion {
                Circle()
                    .trim(from: ringStart, to: ringEnd)
                    .stroke(
                        .quaternary,
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(PlatformMetrics.profileCompletionRingRotationDegrees))

                Circle()
                    .trim(
                        from: ringStart,
                        to: ringStart + (ringEnd - ringStart) * normalizedCompletion
                    )
                    .stroke(
                        Color.accentColor,
                        style: StrokeStyle(lineWidth: progressLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(PlatformMetrics.profileCompletionRingRotationDegrees))
            }

            PlatformListAvatarView(name: name, photo: photo, side: side)
                .padding(avatarInset)
        }
        .frame(width: side + avatarInset * 2, height: side + avatarInset * 2)
        .overlay(alignment: .topLeading) {
            if let percentage {
                Text("\(percentage)%")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(percentage == 100 ? PlatformStatus.success : .secondary)
                    .monospacedDigit()
                    .padding(.horizontal, PlatformMetrics.chipPaddingHorizontalMini)
                    .padding(.vertical, PlatformMetrics.chipPaddingVerticalMini)
                    .background(PlatformSurface.elevated, in: Capsule())
                    .shadow(
                        color: .black.opacity(PlatformMetrics.profileCompletionBadgeShadowOpacity),
                        radius: PlatformMetrics.profileCompletionBadgeShadowRadius,
                        y: PlatformMetrics.avatarBadgeOffset
                    )
                    .offset(
                        x: -PlatformMetrics.profileCompletionBadgeNudge,
                        y: -PlatformMetrics.profileCompletionBadgeNudge
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("头像")
        .accessibilityValue(percentage.map { "资料完整度 \($0)%" } ?? "")
    }
}
