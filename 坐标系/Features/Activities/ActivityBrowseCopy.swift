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
        static let followingSubtitle = "你已参加的局，点开接着看"

        static let fillingTitle = "快被约满"
        static func fillingSubtitle(count: Int) -> String {
            count <= 1 ? "名额不多了，想去就先占一席" : "\(count) 场只剩零星名额"
        }

        static let nearbyTitle = "出门就能到"
        static func nearbySubtitle(count: Int) -> String {
            count <= 1 ? "家门口的小局，见面零压力" : "附近 \(count) 场，走几步就能碰面"
        }

        static let freeTitle = "先玩起来"
        static func freeSubtitle(count: Int) -> String {
            count <= 1 ? "不用花钱，先认识同频的人" : "\(count) 场免费局，零门槛先参加"
        }

        static let soonTitle = "这两天就出发"
        static let soonSubtitle = "不用等太久，说走就走"

        static let tonightTitle = "今晚有局"
        static let tonightSubtitle = "今天下班后就能碰面"

        static let weekendTitle = "周末值得去"
        static let weekendSubtitle = "留给周末的好局，提前占位"

        static let forYouTitle = "猜你想去"
        static let forYouSubtitle = "按兴趣、距离和时间排了个序"

        static func interestTitle(_ interest: String) -> String {
            "因为你喜欢「\(interest)」"
        }
        static let interestSubtitle = "同标签活动，先看这几场"

        static func categorySubtitle(_ category: ActivityCategory) -> String {
            "\(category.title)里值得去的局"
        }

        static let rankedTitle = "本周推荐榜"
        static let rankedSubtitle = "按匹配度精选的本周好局"

        static let editorialTitle = "本周主打"
        static let editorialSubtitle = "左右滑，先挑一场参加"

        static let moreTitle = "还有这些局"
        static let moreSubtitle = "慢慢逛，总会撞见想去的"
    }

    // MARK: - See All（列表降级）

    enum SeeAll {
        /// 明示这是列表，不是源轨横滑形态
        static let listCaption = "以列表查看全部"
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
