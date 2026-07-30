//
//  ProfileCompletion.swift
//  坐标系
//
//  「我的」资料完整度：首页环形进度与编辑页共用。
//

import Foundation
import UIKit

enum ProfileCompletion {
    static let fieldCount = 6

    static func ratio(
        hasAvatar: Bool,
        name: String,
        handle: String,
        city: String,
        bio: String,
        interestsCount: Int
    ) -> Double {
        let filled = [
            hasAvatar,
            !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            interestsCount > 0
        ].filter(\.self).count
        return Double(filled) / Double(fieldCount)
    }

    static func ratio(for user: AppUser) -> Double {
        ratio(
            hasAvatar: user.hasAvatarImage,
            name: user.name,
            handle: user.handle,
            city: user.city,
            bio: user.bio,
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
}
