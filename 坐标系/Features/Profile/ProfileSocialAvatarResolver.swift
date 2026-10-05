//
//  ProfileSocialAvatarResolver.swift
//  坐标系
//
//  社交图头像：仅用本机可知边的真图（搭子目录封面）；无则交给 ListAvatar 字标，不注 Sample 脸。
//

import CoordinateModels
import Foundation

@MainActor
enum ProfileSocialAvatarResolver {
    /// 优先搭子发现卡封面；无匹配则 `nil`（UI 用昵称字标，不造假头像）。
    static func photoRef(
        for name: String,
        buddies: BuddiesModel
    ) -> CommunityPhotoRef? {
        buddies.item(for: name)?.profile.coverPhoto
    }
}
