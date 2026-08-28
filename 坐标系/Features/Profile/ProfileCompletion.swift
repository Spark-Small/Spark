//
//  ProfileCompletion.swift
//  坐标系
//
//  「我的」资料完整度：首页环形进度与编辑页共用。
//

import Foundation
import UIKit

/// 7 项资料：头像（自定义上传）、昵称、ID、城市、简介、搭子宣言、兴趣标签。
enum ProfileCompletion {
    static let fieldCount = 7

    static func ratio(
        hasAvatar: Bool,
        name: String,
        handle: String,
        city: String,
        bio: String,
        lookingFor: String = "",
        interestsCount: Int
    ) -> Double {
        let filled = [
            hasAvatar,
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !lookingFor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            interestsCount > 0
        ].filter(\.self).count
        return Double(filled) / Double(fieldCount)
    }

    static func ratio(for user: AppUser) -> Double {
        ratio(
            hasAvatar: user.avatarLocalName != nil,
            name: user.name,
            handle: user.handle,
            city: user.city,
            bio: user.bio,
            lookingFor: user.lookingFor,
            interestsCount: user.interests.count
        )
    }
}

extension AppUser {
    private static let defaultAvatarAssetName = "ProfileDefaultAvatar"

    var hasAvatarImage: Bool {
        avatarLocalName != nil || UIImage(named: Self.defaultAvatarAssetName) != nil
    }

    var localAvatarImage: UIImage? {
        if let name = avatarLocalName,
           let url = CommunityPhotoStore.fileURL(named: name),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        return UIImage(named: Self.defaultAvatarAssetName)
    }

    var hasVoiceIntro: Bool {
        VoiceIntroPresentation.hasIntro(voiceIntroDuration)
    }

    var voiceIntroDurationText: String {
        VoiceIntroPresentation.durationText(voiceIntroDuration)
    }
}
