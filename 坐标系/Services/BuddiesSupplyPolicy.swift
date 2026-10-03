//
//  BuddiesSupplyPolicy.swift
//  坐标系
//
//  陪玩 / 同好发现供给边界：Release 不以 SampleData 为人设交易主路径。
//

import Foundation
import CoordinateFeatureFlags

enum BuddiesSupplyPolicy {
    /// DEBUG 可用样例人设浏览；Release 仅远程供给（未接时为空）。
    static var allowsSampleDiscoverCatalog: Bool {
        FeatureFlags.useSampleBuddiesCatalog
    }

    static var discoverEmptyTitle: String {
        "还没有可约的人"
    }

    static var discoverEmptyDescription: String {
        "同城搭子与陪玩正在接入。想先认识人：去活动现场碰；想建小圈子：到「我的」创建俱乐部。"
    }

    static var browseActivitiesCTA: String { "去活动找人" }
    static var createClubCTA: String { "去我的建俱乐部" }

    static var orgInviteEmptyTitle: String { "暂无可邀请对象" }

    static var orgInviteEmptyDescription: String {
        if allowsSampleDiscoverCatalog {
            return "附近暂时没有可邀请的人"
        }
        return "还没有可邀请的好友。可先去打招呼加好友，或稍后再试。"
    }

    static var orgInviteBrowseCTA: String { "去发现搭子" }
}
