//
//  ProfileMyPostsCopy.swift
//  坐标系
//
//  「我的发帖」文案：顶栏草稿箱入口；广场库「转发」深链仍用 Category 过滤。
//

import Foundation

enum ProfileMyPostsCopy {
    static let navigationTitle = "我的发帖"
    static let searchPrompt = "搜索我的发帖"
    static let composeAccessibility = "发帖"
    static let composeAccessibilityHint = "撰写新的社区帖子"
    /// 空态 actions：短文案，交给系统默认文字按钮字号（勿自挂 `.font` / `.buttonStyle`）。
    static let browseCommunity = "去广场看看"
    static let composeAction = "发帖"

    enum Drafts {
        static let navigationTitle = "草稿箱"
        static let toolbarAccessibility = "草稿箱"
        static let toolbarHint = "查看未发布的帖子草稿"
        static let openHint = "继续编辑这份草稿"
        static let emptyTitle = "草稿箱是空的"
        static let emptyDescription = "发帖时取消或离开，可将内容存入草稿箱；意外退出也会自动保存。"
        static let emptySystemImage = "tray"
        static let deletedFeedback = "已删除草稿"
        static let idleSystemImage = "tray"
        static let filledSystemImage = "tray.full"

        static func mediaCount(_ count: Int) -> String {
            "\(count) 项媒体"
        }

        static func toolbarAccessibilityValue(count: Int) -> String {
            count == 0 ? "无草稿" : "\(count) 篇草稿"
        }
    }

    /// 空态：短标题 + 单行说明，避免挤破系统 title / secondary 层级。
    static let emptyAllTitle = "开始创建发帖库"
    static let emptyAllDescription = "你发布的帖子会出现在这里。"
    static let emptyOriginalTitle = "开始发布原创"
    static let emptyOriginalDescription = "原创帖子会出现在这里。"
    static let emptyRepostTitle = "还没有转发"
    static let emptyRepostDescription = "转发的帖子会出现在这里。"

    /// 广场库深链：全部 / 原创 / 转发（我的发帖顶栏不再提供 Menu）。
    enum Category: String, CaseIterable, Identifiable, Hashable {
        case all
        case original
        case reposts

        var id: String { rawValue }

        var emptyTitle: String {
            switch self {
            case .all: emptyAllTitle
            case .original: emptyOriginalTitle
            case .reposts: emptyRepostTitle
            }
        }

        var emptyDescription: String {
            switch self {
            case .all: emptyAllDescription
            case .original: emptyOriginalDescription
            case .reposts: emptyRepostDescription
            }
        }

        var systemImage: String {
            switch self {
            case .all: "square.and.pencil"
            case .original: "doc.plaintext"
            case .reposts: "arrow.2.squarepath"
            }
        }
    }

    static func engagementLine(likes: Int, comments: Int) -> String {
        "\(likes) 赞 · \(comments) 评"
    }

    static let repostFootnote = "转发"
}
