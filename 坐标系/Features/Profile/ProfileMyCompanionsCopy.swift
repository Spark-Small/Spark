//
//  ProfileMyCompanionsCopy.swift
//  坐标系
//
//  「我的陪玩」文案：分类走顶栏筛选 Menu（对齐搭子 Trailing）；角标见 StatusPresentation。
//

import Foundation

enum ProfileMyCompanionsCopy {
    static let navigationTitle = "我的陪玩"
    static let pickerAccessibility = "预约分类"
    static let filterMenuHint = "按预约状态筛选"

    enum Toolbar {
        static let filter = "分类"
        static let filterActive = "分类（已启用）"
        static let idleSystemImage = "line.3.horizontal.decrease"
    }

    static let emptyUpcomingTitle = "暂无进行中的预约"
    static let emptyUpcomingDescription = "预约陪玩后，待确认到履约中的单会出现在这里。"
    static let emptyPendingTitle = "没有待处理的预约"
    static let emptyPendingDescription = "待确认或待支付的预约会出现在这里。"
    static let emptyActiveTitle = "暂无履约中的预约"
    static let emptyActiveDescription = "支付成功后，履约中的预约会出现在这里。"
    static let emptyPastTitle = "暂无已结束的预约"
    static let emptyPastDescription = "完成、退款或取消的预约会出现在这里。"

    static let browseDiscover = "去搭子看看"

    /// 顶栏 Menu 四类：即将开始 / 待处理 / 履约中 / 已经结束。
    enum Category: String, CaseIterable, Identifiable, Hashable {
        case upcoming
        case pending
        case active
        case past

        var id: String { rawValue }

        /// 默认「即将开始」不算筛选生效（对齐消息「全部」、搭子默认漏斗）。
        var isFilterActive: Bool { self != .upcoming }

        var segmentTitle: String {
            switch self {
            case .upcoming: "即将开始"
            case .pending: "待处理"
            case .active: "履约中"
            case .past: "已经结束"
            }
        }

        var emptyTitle: String {
            switch self {
            case .upcoming: emptyUpcomingTitle
            case .pending: emptyPendingTitle
            case .active: emptyActiveTitle
            case .past: emptyPastTitle
            }
        }

        var emptyDescription: String {
            switch self {
            case .upcoming: emptyUpcomingDescription
            case .pending: emptyPendingDescription
            case .active: emptyActiveDescription
            case .past: emptyPastDescription
            }
        }

        var systemImage: String {
            switch self {
            case .upcoming: "calendar"
            case .pending: "clock.badge.exclamationmark"
            case .active: "person.2.fill"
            case .past: "clock.arrow.circlepath"
            }
        }

        /// 未生效 = 漏斗；生效 = 当前分类图标（对齐搭子 `browseFilterToolbarSystemImage`）。
        var toolbarSystemImage: String {
            isFilterActive ? systemImage : Toolbar.idleSystemImage
        }

        var emptySystemImage: String { systemImage }
    }
}
