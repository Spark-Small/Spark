//
//  ActivityBrowseCopy.swift
//  坐标系
//
//  活动发现页分区文案：面向新用户 — 降低门槛、给理由、给下一步。
//

import Foundation

enum ActivityBrowseCopy {
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
    }
}
