//
//  ActivityBrowseCopy.swift
//  坐标系
//
//  活动发现页分区文案：面向新用户 — 降低门槛、给理由、给下一步。
//

import Foundation
import CoordinateModels

enum ActivityBrowseCopy {
    static let searchPrompt = "搜索活动、地点或主办"

    // MARK: - 长列表推荐分区（活动域）

    enum Shelf {
        static let followingTitle = "接着逛"

        static let fillingTitle = "快被约满"

        static let nearbyTitle = "出门就能到"

        static let freeTitle = "先玩起来"

        static let tonightTitle = "今晚有局"

        static let featuredTitle = "精选"
        static let topChartsTitle = "今日 Top 10"
        static let hotTitle = "热场活动"
        static let newTitle = "新上架"
        static let editorsTitle = "编辑之选"
        static let listTitle = "完整浏览"
    }

    // MARK: - Empty / filter

    enum Empty {
        static let title = "还没有合适的局"
        static let description = "换个分类试试，或者自己开一场，邀请朋友一起"
        static let action = "发起第一场活动"
        static let filteredTitle = "没有符合条件的局"
        static let filteredDescription = "试试放宽分类或筛选条件"
        static let filteredAction = "调整筛选"
        static let searchTitle = "没有搜到相关活动"
        static let searchDescription = "换个关键词，或清空搜索看看全部"
        static let clearSearchAction = "清空搜索"
    }

    enum ScrollAnchor {
        static let discoverBrowse = "discover-browse"
    }

    // MARK: - 货架卡 meta

    @MainActor
    enum ShelfCard {
        static func editorialBadge(for activity: Activity, shelfID: String) -> String? {
            shelfID == "new"
                ? "新"
                : ActivityCardStatus.captionBadge(for: activity, fallback: "新")
        }

        static func editorialMeta(for activity: Activity) -> String {
            let tag = activity.tags.first ?? (activity.isFree ? ActivityCardStatus.free : activity.fee)
            let time = Formatters.activityEventTime(from: activity.date)
            return "\(activity.category.title) · \(tag) · \(time)"
        }

        static func eventBadge(for activity: Activity, shelfID: String) -> String? {
            switch shelfID {
            case "free": ActivityCardStatus.free
            case "nearby": activity.category.shortTitle
            case "filling": ActivityCardStatus.almostFull
            default: ActivityCardStatus.hotBadge(for: activity)
            }
        }

        static func eventMeta(for activity: Activity, shelfID: String) -> String {
            switch shelfID {
            case "nearby": activity.districtLabel
            case "filling": ActivityCardStatus.spotsText(for: activity)
            default: ActivityCardStatus.hotMetaLine(for: activity)
            }
        }
    }
}
