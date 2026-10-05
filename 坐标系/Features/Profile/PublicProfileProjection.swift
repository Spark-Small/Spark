//
//  PublicProfileProjection.swift
//  坐标系
//
//  公开资料投影单一出口：业务只读；编辑写路径仍走 AppUser + Merge UC。
//

import CoordinateModels
import Foundation

/// 业务 / 详情页消费的公开资料投影（本人以 `AppUser` 为准，他人回落目录卡）。
enum PublicProfileProjection {
    /// 详情页字段快照（好友 / 作者 / 搭子等）。
    static func fields(
        nickname: String,
        user: AppUser,
        buddyProfile: BuddyProfile?
    ) -> ProfilePublicFields {
        ProfilePublicFields.resolve(
            nickname: nickname,
            user: user,
            buddyProfile: buddyProfile
        )
    }

    /// 本人详情：目录卡为壳，人口学与墙等以 `AppUser` 覆盖。
    static func buddyProfile(
        _ base: BuddyProfile,
        from user: AppUser
    ) -> BuddyProfile {
        ProfileBuddyDemographics.projecting(base, from: user)
    }

    static func buddyGender(from gender: ProfileGender?) -> BuddyGender? {
        ProfileBuddyDemographics.buddyGender(from: gender)
    }

    static func profileGender(from gender: BuddyGender?) -> ProfileGender? {
        ProfileBuddyDemographics.profileGender(from: gender)
    }
}
