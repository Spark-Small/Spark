//
//  ProfileMyClubsCopy.swift
//  坐标系
//
//  「我的俱乐部」文案：分类走顶栏筛选 Menu；创建在 Trailing。
//

import Foundation

enum ProfileMyClubsCopy {
    static let navigationTitle = "我的俱乐部"
    static let pickerAccessibility = "俱乐部分类"
    static let filterMenuHint = "按创建 / 已加入筛选"

    enum Toolbar {
        static let filter = "分类"
        static let filterActive = "分类（已启用）"
        static let idleSystemImage = "line.3.horizontal.decrease"
    }

    static let createAccessibility = CircleComposeCopy.title
    static let createAccessibilityHint = "填写资料并创建俱乐部"
    static let createAction = CircleComposeCopy.title
    static let browseDiscover = "去发现俱乐部"

    static let emptyAllTitle = "还没有俱乐部"
    static let emptyAllDescription = "创建或加入俱乐部后，会出现在这里。"
    static let emptyHostedTitle = "还没有创建的俱乐部"
    static let emptyHostedDescription = "创建后会出现在这里，也可去发现页加入别人的俱乐部。"
    static let emptyJoinedTitle = "还没有加入的俱乐部"
    static let emptyJoinedDescription = "在搭子发现页加入俱乐部后，会出现在这里。"

    /// 顶栏 Menu：全部 / 我创建的 / 已加入。
    enum Category: String, CaseIterable, Identifiable, Hashable {
        case all
        case hosted
        case joined

        var id: String { rawValue }

        /// 默认「全部」不算筛选生效。
        var isFilterActive: Bool { self != .all }

        var segmentTitle: String {
            switch self {
            case .all: "全部"
            case .hosted: "我创建的"
            case .joined: "已加入"
            }
        }

        var emptyTitle: String {
            switch self {
            case .all: emptyAllTitle
            case .hosted: emptyHostedTitle
            case .joined: emptyJoinedTitle
            }
        }

        var emptyDescription: String {
            switch self {
            case .all: emptyAllDescription
            case .hosted: emptyHostedDescription
            case .joined: emptyJoinedDescription
            }
        }

        var systemImage: String {
            switch self {
            case .all: "person.3"
            case .hosted: "flag"
            case .joined: "person.crop.circle.badge.checkmark"
            }
        }

        var toolbarSystemImage: String {
            isFilterActive ? systemImage : Toolbar.idleSystemImage
        }

        var emptySystemImage: String { systemImage }
    }
}
