//
//  BuddyFilterSupport.swift
//  坐标系
//
//  筛选路由、距离常量、俱乐部排序与三模式文案。
//

import SwiftUI
import CoordinateModels

enum BuddyFilterRoute: Hashable {
    case provinces
    case cities(String)
    case hobbies
}

enum BuddyFilterDistance {
    static let minimumKilometers: Double = 1
    static let maximumKilometers: Double = 20
}

/// 俱乐部列表排序（Meetup / 小组类：活跃 · 规模 · 新）。
enum BuddyClubSort: String, CaseIterable, Identifiable {
    case active = "周活跃"
    case members = "成员多"
    case newest = "最新"

    var id: String { rawValue }
}

nonisolated enum BuddyFilterCopy {
    static let sheetTitle = "筛选"
    static let regionHeader = "地区"
    static let regionFooter = "默认跟随定位城市；需要跨城浏览时，再指定城市。"
    static let clubRegionFooter = "按俱乐部所在城市浏览；默认同城定位。"
    static let useLocation = "使用定位"
    static let openLocationSettings = "打开定位设置"
    static let pickCity = "指定城市"
    static let pickProvinceHeader = "选择省份 / 直辖市"
    static let genderHeader = "性别"
    static let genderAny = "不限"
    static let genderFemale = "女生"
    static let genderMale = "男生"
    static let distanceHeader = "距离"
    static let distanceNear = "近"
    static let distanceFar = "远"
    static let distanceFooter = "左右滑动设定可接受的最远距离。"
    static let hobbyHeader = "兴趣"
    static let hobbyFooter = "点进去选择一项兴趣；列表含全部可选标签。"
    static let hobbyPickHeader = "选择兴趣"
    static let hobbyPickFooter = "与找搭子兴趣标签一致。"
    static let hobbyAny = "不限"
    static let cityUnspecified = "未指定"
    static let peopleSortHeader = "排序"
    static let peopleSortRecommended = "推荐"
    static let peopleSortActive = "刚活跃"
    static let bookingSortHeader = "排序"
    static let clubSortHeader = "排序"
    static let clubTopicHeader = "主题"
    static let clubTopicAny = "不限"
    static let reset = "重置"
    static let apply = "完成"
    static let moreFilters = "更多筛选…"

    static let freeMenuHint = "排序、性别即时生效；地区、距离与兴趣在更多筛选"
    static let paidMenuHint = "排序、可约、服务类型与性别即时生效；地区与距离在更多筛选"
    static let clubMenuHint = "排序与主题即时生效；城市在更多筛选"
    /// 兼容旧引用；按当前模式应由调用方传入专用 hint。
    static let menuHint = freeMenuHint
}

#Preview {
    @Previewable @State var filter = BuddyFilter()
    @Previewable @State var usesLocation = true
    @Previewable @State var cityID = BuddyCityCatalog.default.id
    BuddyFilterSheet(
        filter: $filter,
        usesSystemLocation: $usesLocation,
        selectedCityID: $cityID,
        locatedPlaceName: "上海",
        needsLocationPermission: false,
        onUseSystemLocation: {},
        onOpenSettings: {}
    )
}
