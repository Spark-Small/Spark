//
//  EditProfileSheet+Avatar.swift
//  坐标系
//
//  个人资料：头像导入 / 移除。
//

import CoordinateModels
import PhotosUI
import SwiftUI
import UIKit

extension EditProfileSheet {
    func removeAvatar() {
        if let avatarLocalName,
           avatarLocalName != user.avatarLocalName {
            LocalMediaLibrary.delete(named: avatarLocalName)
        }
        avatarLocalName = nil
        avatarPreview = UIImage(named: "ProfileDefaultAvatar")
        pickerItem = nil
    }

    @MainActor
    func loadAvatar(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isPreparingAvatar = true
        defer { isPreparingAvatar = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else { return }
        let decision = await MediaModerationService.moderateImageData(
            data,
            context: .avatar,
            actorKey: user.name
        )
        if case .block(let reason) = decision {
            moderationAlert = reason
            return
        }
        guard let saved = LocalMediaLibrary.saveJPEG(data) else { return }
        if let previous = avatarLocalName, previous != user.avatarLocalName {
            LocalMediaLibrary.delete(named: previous)
        }
        avatarPreview = image
        avatarLocalName = saved
    }
}
