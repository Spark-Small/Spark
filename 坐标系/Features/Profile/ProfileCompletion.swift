//
//  ProfileCompletion.swift
//  坐标系
//
//  「好读懂」资料完整度：编辑环与「我的」进度共用（软激励，非硬门闸）。
//

import Foundation
import UIKit
import CoordinateModels

/// 6 项「好读懂」：头像、≥3 墙图、简介、≥1 Prompt、性别、年龄。
enum ProfileCompletion {
    static let fieldCount = 6
    static let galleryReadableMinimum = 3

    static func ratio(
        hasAvatar: Bool,
        galleryCount: Int,
        bio: String,
        promptsCount: Int,
        hasGender: Bool,
        hasAge: Bool
    ) -> Double {
        let filled = [
            hasAvatar,
            galleryCount >= galleryReadableMinimum,
            !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            promptsCount >= 1,
            hasGender,
            hasAge
        ].filter(\.self).count
        return Double(filled) / Double(fieldCount)
    }

    static func ratio(for user: AppUser) -> Double {
        ratio(
            hasAvatar: user.avatarLocalName != nil,
            galleryCount: user.galleryLocalNames.count,
            bio: user.bio,
            promptsCount: user.prompts.count,
            hasGender: user.gender != nil,
            hasAge: (user.age ?? 0) > 0
        )
    }
}

extension AppUser {
    private static let defaultAvatarAssetName = "ProfileDefaultAvatar"

    @MainActor
    var hasAvatarImage: Bool {
        avatarLocalName != nil || UIImage(named: Self.defaultAvatarAssetName) != nil
    }

    @MainActor
    var localAvatarImage: UIImage? {
        if let name = avatarLocalName,
           let url = LocalMediaLibrary.fileURL(named: name),
           let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            return image
        }
        return UIImage(named: Self.defaultAvatarAssetName)
    }

    @MainActor
    func localVerificationImages() -> [UIImage] {
        verificationPhotos.compactMap { photo in
            guard let url = LocalMediaLibrary.fileURL(named: photo.localName),
                  let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data)
            else { return nil }
            return image
        }
    }

    @MainActor
    func localPublicVerificationImages() -> [UIImage] {
        publicVerificationPhotos.compactMap { photo in
            guard let url = LocalMediaLibrary.fileURL(named: photo.localName),
                  let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data)
            else { return nil }
            return image
        }
    }

    var hasVoiceIntro: Bool {
        VoiceIntroPresentation.hasIntro(voiceIntroDuration)
    }

    var voiceIntroDurationText: String {
        VoiceIntroPresentation.durationText(voiceIntroDuration)
    }
}
