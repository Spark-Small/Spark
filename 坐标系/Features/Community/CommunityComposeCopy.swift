//
//  CommunityComposeCopy.swift
//  坐标系
//
//  发分享 Sheet 文案。
//

import Foundation

enum CommunityComposeCopy {
    static let navigationTitle = "发分享"
    static let cancel = "取消"
    static let publish = "发布"

    static let bodySection = "内容"
    static let bodyPlaceholder = "写下路线、体验或避坑…"
    static let bodyFooter = "适合活动复盘、探店笔记和路线攻略"

    static let mediaEmptyTitle = "添加照片或视频"
    static let mediaSection = "照片与视频"
    static let mediaProcessing = "正在处理媒体…"
    static let removePhotoAccessibility = "移除照片"
    static func mediaFooter(maxPhotos: Int) -> String {
        "最多 \(maxPhotos) 项，发布后保存在本机"
    }

    static let tagsSection = "标签"
    static let tagsPlaceholder = "用空格分隔，如 夜骑 新手"

    static let photoImportFailed = "无法导入所选图片，请换一张再试"
    static let photoImportRetry = "重试导入"
    static let photoImportDismiss = "知道了"

    static let sensitiveTitle = "内容需要修改"
    static let sensitiveDismiss = "知道了"
    static func sensitiveMessage(_ word: String) -> String {
        "检测到敏感词「\(word)」，请修改后再发布。"
    }

    static func photoImportPartialCount(_ count: Int) -> String {
        "有 \(count) 项未能导入，已保留可加载的媒体。"
    }
}
