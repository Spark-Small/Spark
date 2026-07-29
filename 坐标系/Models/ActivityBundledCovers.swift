//
//  ActivityBundledCovers.swift
//  坐标系
//
//  种子活动内置封面（Asset Catalog），按稳定 ID 映射。
//

import Foundation

enum ActivityBundledCovers {
    /// 外滩夜骑 / 思南咖啡 / 徐汇市集 / 微醺小酌 / 烧烤夜局
    static let nightRide = "ActivityCoverNightRide"
    static let cafe = "ActivityCoverCafe"
    static let market = "ActivityCoverMarket"
    static let cocktails = "ActivityCoverCocktails"
    static let beer = "ActivityCoverBeer"

    private static let namesByID: [UUID: String] = [
        SampleData.activityID(2): nightRide,
        SampleData.activityID(3): cafe,
        SampleData.activityID(4): market,
        SampleData.activityID(5): beer,
        SampleData.activityID(29): cocktails,
    ]

    static func assetName(for id: Activity.ID) -> String? {
        namesByID[id]
    }
}
