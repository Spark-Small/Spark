//
//  PlatformMetrics+ProfileChrome.swift
//  坐标系
//
//  「我的」资料完整度环 / 角标尺寸（从 PlatformMetrics 主表拆出，免堆 >400）。
//

import CoreGraphics

extension PlatformMetrics {
    /// 资料完整度环：开口起止（相对圆周 0…1）与旋转。
    static var profileCompletionRingTrimStart: CGFloat { 0.10 }
    static var profileCompletionRingTrimEnd: CGFloat { 0.90 }
    static var profileCompletionRingRotationDegrees: Double { -135 }
    /// 完整度 `%` 胶囊相对头像左上角的轻推（≈ 2× 角标偏移）。
    static var profileCompletionBadgeNudge: CGFloat { avatarBadgeOffset * 2 }
    static var profileCompletionBadgeShadowOpacity: Double { 0.12 }
    static var profileCompletionBadgeShadowRadius: CGFloat { hairlineSpacing }
}
