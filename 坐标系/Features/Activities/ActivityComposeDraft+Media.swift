//
//  ActivityComposeDraft+Media.swift
//  坐标系
//
//  发起活动草稿：媒体选择、预览与本机库提交。
//

import PhotosUI
import SwiftUI
import UIKit
import CoordinateModels

extension ActivityComposeDraft {
    func removeMedia(at index: Int) {
        guard mediaNames.indices.contains(index) else { return }
        let name = mediaNames.remove(at: index)
        mediaPreviews.removeValue(forKey: name)
    }

    func discardUncommittedMediaIfNeeded() {
        LocalMediaLibrary.discardUncommitted(current: mediaNames, baseline: baselineMediaNames)
    }

    func commitMediaRemovalsIfNeeded() {
        LocalMediaLibrary.commitRemovals(current: mediaNames, baseline: baselineMediaNames)
        baselineMediaNames = mediaNames
    }

    func loadMedia(_ items: [PhotosPickerItem], actorKey: String) async {
        guard !items.isEmpty else { return }
        isPreparingMedia = true
        defer {
            isPreparingMedia = false
            mediaPickerItems = []
        }

        for item in items {
            guard mediaNames.count < Self.maxMediaCount else { break }
            guard let name = await LocalMediaLibrary.savePickerItem(item),
                  let url = LocalMediaLibrary.fileURL(named: name)
            else { continue }

            let preview: UIImage?
            if LocalMediaLibrary.isVideo(url: url) {
                preview = await LocalMediaLibrary.posterImage(for: url)
            } else {
                preview = await PlatformLocalImageCache.loadAsync(atPath: url.path)
            }
            guard let preview else {
                LocalMediaLibrary.delete(named: name)
                continue
            }

            let decision = await MediaModerationService.moderateImage(
                preview,
                context: .activityCover,
                actorKey: actorKey
            )
            if case .block(let reason) = decision {
                LocalMediaLibrary.delete(named: name)
                moderationAlert = reason
                continue
            }

            mediaNames.append(name)
            mediaPreviews[name] = preview
        }
    }

    func hydrateMediaPreviews() async {
        for name in mediaNames {
            guard mediaPreviews[name] == nil else { continue }
            if let image = await Self.previewImage(named: name) {
                mediaPreviews[name] = image
            }
        }
    }

    static func previewImage(named name: String) async -> UIImage? {
        guard let url = LocalMediaLibrary.fileURL(named: name) else { return nil }
        if LocalMediaLibrary.isVideo(url: url) {
            return await LocalMediaLibrary.posterImage(for: url)
        }
        return await PlatformLocalImageCache.loadAsync(atPath: url.path)
    }

}
