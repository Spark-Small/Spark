//
//  ActivityBrowseCopy.swift
//  坐标系
//
//  活动发现页分区文案：面向新用户 — 降低门槛、给理由、给下一步。
//

import Foundation
import CoordinateModels

enum ActivityBrowseCopy {
    static let reloadFailed = "活动列表刷新失败，请稍后重试"
    static let favoritesLibrary = "我的收藏"
    static let favoritesLibraryHint = "查看我收藏的活动"
    static let recentsTitle = "最近看过"
    static let recentsEmptyTitle = "还没有看过的活动"
    static let recentsEmptyDescription = "打开活动详情后会出现在这里"
    static let recentsClear = "清空"

    // MARK: - 长列表推荐分区（活动域）

    enum Shelf {
        static let followingTitle = "接着逛"
        static let fillingTitle = "快被约满"
        static let nearbyTitle = "出门就能到"
        static let freeTitle = "先玩起来"
        static let tonightTitle = "今晚有局"
        static let hotTitle = "热场活动"
    }

    // MARK: - Empty / filter

    enum Empty {
        static let title = "还没有合适的局"
        static let description = "换个分类再找，或自己开一场邀请朋友参加"
        static var action: String { ActivityComposeCopy.createTitle }
        static let filteredTitle = "没有符合条件的局"
        static let filteredDescription = "放宽筛选后再找一场参加"
        static let filteredAction = "清除条件"
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
