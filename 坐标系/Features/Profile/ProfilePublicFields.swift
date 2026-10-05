//
//  ProfilePublicFields.swift
//  坐标系
//
//  用户详情展示字段实现。业务请走 `PublicProfileProjection.fields`。
//

import CoordinateModels
import Foundation

/// 详情页可读字段快照（不含头像 UIImage，避免跨层耦合）。
struct ProfilePublicFields: Equatable {
    var isSelf: Bool
    var city: String
    var bio: String
    var tags: [String]
    var handle: String
    var galleryRefs: [CommunityPhotoRef]
    var voiceIntroDuration: Double?
    var voiceIntroCaption: String?
    var gender: ProfileGender?
    var age: Int?
    var heightCM: Int?
    var weightKG: Int?
    var availability: String
    var intents: [ProfileIntent]
    var prompts: [ProfilePrompt]
    var occupation: ProfileOccupation?
    var meetRadius: ProfileMeetRadius?
    var mbti: ProfileMBTI?
    var zodiac: ProfileZodiac?
    var lookingFor: String

    var hasVoiceIntro: Bool {
        VoiceIntroPresentation.hasIntro(voiceIntroDuration)
    }

    var intentDisplayLine: String {
        ProfileIntentLimits.displayLine(intents: intents, legacyLookingFor: lookingFor)
    }

    var hasBasics: Bool {
        gender != nil
            || (age ?? 0) > 0
            || (heightCM ?? 0) > 0
            || (weightKG ?? 0) > 0
            || !availability.isEmpty
            || occupation != nil
            || meetRadius != nil
            || mbti != nil
            || zodiac != nil
            || !intentDisplayLine.isEmpty
    }

    /// - Parameters:
    ///   - nickname: 详情主体昵称
    ///   - user: 当前登录用户（本人时作为唯一录入源）
    ///   - buddyProfile: 发现目录卡（他人或非本人回落）
    static func resolve(
        nickname: String,
        user: AppUser,
        buddyProfile: BuddyProfile?
    ) -> ProfilePublicFields {
        let isSelf = nickname.caseInsensitiveCompare(user.name) == .orderedSame
        if isSelf {
            let gallery = user.galleryLocalNames.compactMap { name -> CommunityPhotoRef? in
                LocalMediaLibrary.fileURL(named: name).map(CommunityPhotoRef.file)
            }
            return ProfilePublicFields(
                isSelf: true,
                city: user.city.trimmingCharacters(in: .whitespacesAndNewlines),
                bio: user.bio.trimmingCharacters(in: .whitespacesAndNewlines),
                tags: user.interests,
                handle: user.handle.trimmingCharacters(in: .whitespacesAndNewlines),
                galleryRefs: gallery,
                voiceIntroDuration: user.voiceIntroDuration,
                voiceIntroCaption: user.voiceIntroCaption,
                gender: user.gender,
                age: user.age,
                heightCM: user.heightCM,
                weightKG: user.weightKG,
                availability: user.availability.trimmingCharacters(in: .whitespacesAndNewlines),
                intents: user.intents,
                prompts: user.prompts,
                occupation: user.occupation,
                meetRadius: user.meetRadius,
                mbti: user.mbti,
                zodiac: user.displayZodiac,
                lookingFor: user.lookingFor
            )
        }
        let profile = buddyProfile
        return ProfilePublicFields(
            isSelf: false,
            city: profile?.city.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            bio: profile?.bio.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            tags: profile?.tags ?? [],
            handle: "",
            galleryRefs: profile?.lifeGalleryRefs ?? [],
            voiceIntroDuration: profile?.voiceIntroDuration,
            voiceIntroCaption: profile?.voiceIntroCaption,
            gender: ProfileBuddyDemographics.profileGender(from: profile?.gender),
            age: (profile?.age ?? 0) > 0 ? profile?.age : nil,
            heightCM: (profile?.heightCM ?? 0) > 0 ? profile?.heightCM : nil,
            weightKG: (profile?.weightKG ?? 0) > 0 ? profile?.weightKG : nil,
            availability: profile?.availability.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            intents: profile?.intents ?? [],
            prompts: profile?.prompts ?? [],
            occupation: profile?.occupation,
            meetRadius: profile?.meetRadius,
            mbti: profile?.mbti,
            zodiac: profile?.zodiac,
            lookingFor: profile?.lookingFor ?? ""
        )
    }
}
