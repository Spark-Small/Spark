//
//  LocalMediaLibrary.swift
//  坐标系
//
//  Feature Model 拥有的本地媒体门面（Apple：View 不直连磁盘 I/O）。
//  底层仍复用 CommunityPhotoStore 文件布局，避免迁移历史文件名。
//  仅写失败上报标 @MainActor；读写 API 保持非隔离，避免 PhotosPicker 标签闭包冲突。
//

import Foundation
import PhotosUI
import SwiftUI
import UIKit
import CoordinateModels

enum LocalMediaLibrary {
    static var photosAndVideos: PHPickerFilter { CommunityPhotoStore.photosAndVideos }

    static func fileURL(named name: String) -> URL? {
        CommunityPhotoStore.fileURL(named: name)
    }

    static func mediaRef(named name: String) -> CommunityPhotoRef? {
        CommunityPhotoStore.mediaRef(named: name)
    }

    static func isVideo(url: URL) -> Bool {
        CommunityPhotoStore.isVideo(url: url)
    }

    static func isVideo(name: String) -> Bool {
        CommunityPhotoStore.isVideo(name: name)
    }

    @MainActor
    @discardableResult
    static func saveJPEG(_ data: Data, quality: CGFloat = 0.82) -> String? {
        let name = CommunityPhotoStore.saveJPEG(data, quality: quality)
        if name == nil {
            PersistenceWriteFailureReporter.record(
                domainKey: "localMedia",
                error: CocoaError(.fileWriteUnknown)
            )
        }
        return name
    }

    @MainActor
    @discardableResult
    static func saveJPEG(_ image: UIImage, quality: CGFloat = 0.82) -> String? {
        let name = CommunityPhotoStore.saveJPEG(image, quality: quality)
        if name == nil {
            PersistenceWriteFailureReporter.record(
                domainKey: "localMedia",
                error: CocoaError(.fileWriteUnknown)
            )
        }
        return name
    }

    static func savePickerItem(_ item: PhotosPickerItem) async -> String? {
        await CommunityPhotoStore.savePickerItem(item)
    }

    static func posterImage(for url: URL) async -> UIImage? {
        await CommunityPhotoStore.posterImage(for: url)
    }

    static func delete(named name: String) {
        CommunityPhotoStore.delete(named: name)
    }

    static func discardUncommitted(current: [String], baseline: [String]) {
        CommunityPhotoStore.discardUncommitted(current: current, baseline: baseline)
    }

    static func commitRemovals(current: [String], baseline: [String]) {
        CommunityPhotoStore.commitRemovals(current: current, baseline: baseline)
    }

    static func copyMovie(from file: URL) throws -> URL {
        try CommunityPhotoStore.copyMovie(from: file)
    }

    static func resetAll() {
        CommunityPhotoStore.resetAll()
    }
}
