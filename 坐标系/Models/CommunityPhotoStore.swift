//
//  CommunityPhotoStore.swift
//  坐标系
//

import Foundation
import UIKit

/// 社区本地配图：写入 Application Support，随帖子持久化引用文件名
enum CommunityPhotoStore {
    private static let folderName = "CommunityPhotos"

    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func fileURL(named name: String) -> URL? {
        let url = directory.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    @discardableResult
    static func saveJPEG(_ data: Data, quality: CGFloat = 0.82) -> String? {
        guard let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: quality)
        else { return nil }

        let name = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(name)
        do {
            try jpeg.write(to: url, options: .atomic)
            return name
        } catch {
            return nil
        }
    }

    static func delete(named name: String) {
        let url = directory.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: url)
    }

    /// 丢弃会话中新写入、最终未提交的图片（取消编辑时调用）
    static func discardUncommitted(current: [String], baseline: [String]) {
        let orphans = Set(current).subtracting(baseline)
        for name in orphans {
            delete(named: name)
        }
    }

    /// 提交时删除基线里已去掉的文件
    static func commitRemovals(current: [String], baseline: [String]) {
        let removed = Set(baseline).subtracting(current)
        for name in removed {
            delete(named: name)
        }
    }

    static func resetAll() {
        try? FileManager.default.removeItem(at: directory)
    }
}
