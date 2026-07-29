//
//  BuddyDetailCopy.swift
//  坐标系
//
//  搭子 / 陪玩详情文案。
//

import Foundation

nonisolated enum BuddyDetailCopy {
    static let greet = "打招呼"
    static let invite = "邀约一起"
    static let book = "预约陪玩"
    static let bookUnavailable = "暂不可约"

    static let basicInfoTitle = "基本资料"
    static let aboutTitle = "关于"
    static let serviceTitle = "服务"
    static let matchTitle = "共同兴趣"
    static let reasonTitle = "推荐理由"
    static let scheduleTitle = "可约档期"
    static let scheduleEmpty = "暂未公开档期"
    static let reviewsTitle = "评价"
    static let reviewsEmpty = "还没有评价"
    static let relatedTitle = "可以一起去"
    static let circleTitle = "所在组织"
    static let trustTitle = "资料"

    static let verifiedBadge = "平台认证"
    static let online = "在线"
    static let offline = "离线"
    static let available = "可约"
    static let unavailable = "档期已满"

    static let genderLabel = "性别"
    static let ageLabel = "年龄"
    static let heightLabel = "身高"
    static let weightLabel = "体重"
    static let cityLabel = "地区"
    static let distanceLabel = "距离"
    static let activeLabel = "最近活跃"
    static let lookingLabel = "想找"
    static let availabilityLabel = "空闲"
    static let serviceTypeLabel = "服务类型"
    static let specialtyLabel = "擅长"
    static let priceLabel = "价格"
    static let ratingLabel = "评分"
    static let ordersLabel = "成单"
    static let responseLabel = "响应"

    static func ageValue(_ age: Int) -> String { "\(age) 岁" }
    static func ordersValue(_ count: Int) -> String { "\(count) 单" }
    static func ratingValue(_ rating: Double) -> String {
        String(format: "%.1f", rating)
    }

    static func reviewCount(_ count: Int) -> String {
        count == 0 ? "暂无评价" : "\(count) 条评价"
    }

    static func photosCount(_ count: Int) -> String { "\(count) 张" }

    static func greetAccessibility(nickname: String) -> String {
        "向\(nickname)打招呼"
    }

    static func inviteAccessibility(nickname: String) -> String {
        "邀约\(nickname)一起参加活动"
    }

    static func bookAccessibility(nickname: String) -> String {
        "预约\(nickname)陪玩"
    }
}
