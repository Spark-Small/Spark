//
//  CommunitySheetCopy.swift
//  坐标系
//
//  广场互动 Sheet（分享 / 收藏 / 转发）。
//

import Foundation

enum CommunitySheetCopy {
    static let shareTitle = "分享"
    static let startChat = "发起聊天"
    static let sendToSection = "发送给"
    static let noContacts = "暂无联系人"
    static let noMatch = "无匹配结果"
    static let moreSection = "更多"
    static let viewRepost = "查看转发"
    static let repostToCommunity = "转发到社区"
    static let quoteRepost = "引用转发"
    static let linkCopied = "已复制链接"
    static let copyLink = "复制链接"
    static let shareToSystem = "分享到…"
    static let searchContactsPrompt = "搜索联系人"

    static let quoteRepostTitle = "引用转发"
    static let quotePlaceholder = "写下你的想法…"
    static let cancel = "取消"
    static let publish = "发布"

    static let repostDetailTitle = "转发详情"
    static let originalSection = "原文"
    static let myRepostsSection = "我的转发"
    static let myRepostsEmpty = "暂无转发记录"

    static let bookmarkTitle = "收藏"
    static let bookmarkToHeader = "收藏到"
    static let createCollection = "创建收藏夹…"
    static let createCollectionTitle = "创建收藏夹"
    static let collectionNamePlaceholder = "收藏夹名称"
    static let createCollectionFooter = "创建后，这条分享会放进该收藏夹。"
    static let create = "创建"
    static let presetCollections = ["私密", "全部收藏", "周末路线", "探店笔记", "稍后看"]

    static func sentTo(_ name: String) -> String { "已发送给\(name)" }
    static func sendTo(_ name: String) -> String { "发送给\(name)" }
}
