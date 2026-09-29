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
        "真人供给接入中"
    }

    static var discoverEmptyDescription: String {
        "同城同好与陪玩将由服务端下发。当前可先浏览活动，或创建自己的俱乐部。"
    }
}
