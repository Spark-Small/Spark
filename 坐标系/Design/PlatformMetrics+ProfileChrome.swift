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
    /// 照片/发帖三列细缝 = 系统物理细线。
    static var profilePhotoGridSpacing: CGFloat { separatorHairline }
    /// 媒体格角标内边距（与画廊删除角标同探针）。
    static var profileMediaGlyphInset: CGFloat { galleryRemoveBadgeOffset }
    /// 媒体格角标阴影半径 / 不透明度（与资料完整度角标同族）。
    static var profileMediaGlyphShadowRadius: CGFloat { profileCompletionBadgeShadowRadius }
    static var profileMediaGlyphShadowOpacity: Double { profileCompletionBadgeShadowOpacity }
}
