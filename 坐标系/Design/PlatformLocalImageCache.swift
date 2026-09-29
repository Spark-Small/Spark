//
//  PlatformLocalImageCache.swift
//  坐标系
//
//  聊天 / 本地文件图：后台解码 + 内存缓存，避免 List body 同步读盘。
//

import SwiftUI
import UIKit

enum PlatformLocalImageCache {
    /// `NSCache` is thread-safe; wrap for Swift 6 static Sendable checking.
    private static let box = CacheBox()

    static func image(atPath path: String) -> UIImage? {
        let key = path as NSString
        if let cached = box.cache.object(forKey: key) { return cached }
        guard let image = UIImage(contentsOfFile: path) else { return nil }
        box.cache.setObject(image, forKey: key)
        return image
    }

    static func loadAsync(atPath path: String) async -> UIImage? {
        let key = path as NSString
        if let cached = box.cache.object(forKey: key) { return cached }
        let image = await Task.detached(priority: .userInitiated) {
            UIImage(contentsOfFile: path)
        }.value
        if let image {
            box.cache.setObject(image, forKey: key)
        }
        return image
    }
}

private final class CacheBox: @unchecked Sendable {
    let cache = NSCache<NSString, UIImage>()
}

/// 本地文件异步图：占位 → 解码完成替换。
struct PlatformAsyncFileImage: View {
    let fileURL: URL?
    var placeholder: String = "图片"

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(placeholder)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.tertiarySystemFill))
            }
        }
        .task(id: fileURL?.path) {
            image = nil
            guard let path = fileURL?.path else { return }
            image = await PlatformLocalImageCache.loadAsync(atPath: path)
        }
    }
}
