//
//  ProfileBuddyDemographics.swift
//  坐标系
//
//  本人 BuddyProfile 投影实现。业务请走 `PublicProfileProjection.buddyProfile`。
//

import CoordinateModels
import Foundation

enum ProfileBuddyDemographics {
    static func buddyGender(from gender: ProfileGender?) -> BuddyGender? {
        guard let gender else { return nil }
        return BuddyGender(rawValue: gender.rawValue)
    }

    static func profileGender(from gender: BuddyGender?) -> ProfileGender? {
        guard let gender else { return nil }
        return ProfileGender(rawValue: gender.rawValue)
    }

    /// 本人详情用：目录卡为壳，人口学 / 城市 / 简介 / 兴趣 / 语音 / 档期一律以 `AppUser` 为准。
    static func projecting(_ base: BuddyProfile, from user: AppUser) -> BuddyProfile {
        var profile = base
        let city = user.city.trimmingCharacters(in: .whitespacesAndNewlines)
        if !city.isEmpty { profile.city = city }
        let bio = user.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        if !bio.isEmpty { profile.bio = bio }
        if !user.interests.isEmpty { profile.tags = user.interests }
        if let gender = buddyGender(from: user.gender) {
            profile.gender = gender
        }
        if let age = user.age, age > 0 {
            profile.age = age
        } else {
            profile.age = 0
        }
        if let height = user.heightCM, height > 0 {
            profile.heightCM = height
        } else {
            profile.heightCM = 0
        }
        if let weight = user.weightKG, weight > 0 {
            profile.weightKG = weight
        } else {
            profile.weightKG = 0
        }
        let availability = user.availability.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.availability = availability
        profile.voiceIntroDuration = user.voiceIntroDuration
        profile.voiceIntroCaption = user.voiceIntroCaption
        profile.intents = user.intents
        profile.prompts = user.prompts
        profile.occupation = user.occupation
        profile.meetRadius = user.meetRadius
        profile.mbti = user.mbti
        profile.zodiac = user.displayZodiac
        profile.galleryLocalNames = user.galleryLocalNames
        profile.lookingFor = user.intentDisplayLine
        return profile
    }
}
