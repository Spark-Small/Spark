//
//  PlatformMessageBadgeDots.swift
//  坐标系
//
//  未读 / 在线等头像角标圆点。
//

import SwiftUI

struct PlatformUnreadDot: View {
    var body: some View {
        PlatformAvatarBadgeDot(fill: PlatformStatus.danger)
            .accessibilityHidden(true)
    }
}

/// 头像角标圆点（在线 / 未读共用尺寸与描边）
struct PlatformAvatarBadgeDot: View {
    var fill: Color

    var body: some View {
        Circle()
            .fill(fill)
            .frame(
                width: PlatformMessagesChrome.presenceDotSize,
                height: PlatformMessagesChrome.presenceDotSize
            )
            .overlay {
                Circle()
                    .stroke(Color(.systemBackground), lineWidth: PlatformMetrics.avatarBadgeStroke)
            }
    }
}

/// 在线状态点（系统 success）
struct PlatformPresenceDot: View {
    var body: some View {
        PlatformAvatarBadgeDot(fill: PlatformStatus.success)
    }
}
