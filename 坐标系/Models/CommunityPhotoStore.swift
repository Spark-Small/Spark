//
//  CommunityPhotoStore.swift
//  坐标系
//

import AVFoundation
import Foundation
import UniformTypeIdentifiers
import UIKit

/// 社区本地媒体：写入 Application Support，随帖子 / 相册持久化引用文件名
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

    static func isVideo(url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if ["mp4", "mov", "m4v", "mpeg", "mpg"].contains(ext) { return true }
        return UTType(filenameExtension: ext)?.conforms(to: .movie) == true
    }

    static func isVideo(name: String) -> Bool {
        isVideo(url: URL(fileURLWithPath: name))
    }

    static func mediaRef(named name: String) -> CommunityPhotoRef? {
        fileURL(named: name).map(CommunityPhotoRef.file)
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

    static func posterImage(for url: URL) async -> UIImage? {
        await VideoPosterCache.shared.image(for: url)
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

    static func copyMovie(from source: URL) throws -> URL {
        let ext = source.pathExtension.isEmpty ? "mp4" : source.pathExtension
        let dest = directory.appendingPathComponent("\(UUID().uuidString).\(ext)")
        let accessed = source.startAccessingSecurityScopedResource()
        defer {
            if accessed { source.stopAccessingSecurityScopedResource() }
        }
        try FileManager.default.copyItem(at: source, to: dest)
        return dest
    }
}

private final class VideoPosterCache: @unchecked Sendable {
    static let shared = VideoPosterCache()
    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) async -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1200, height: 1200)
        let time = CMTime(seconds: 0.1, preferredTimescale: 600)

        return await withCheckedContinuation { continuation in
            generator.generateCGImageAsynchronously(for: time) { [weak self] cgImage, _, _ in
                let image = cgImage.map { UIImage(cgImage: $0) }
                if let image {
                    self?.cache.setObject(image, forKey: url as NSURL)
                }
                continuation.resume(returning: image)
            }
        }
    }
}

