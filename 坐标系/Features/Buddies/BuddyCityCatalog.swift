//
//  BuddyCityCatalog.swift
//  坐标系
//
//  搭子省市目录：省 → 市两级，供完整筛选 Sheet。
//

import Foundation

struct BuddyCityChoice: Identifiable, Hashable {
    let province: String
    let city: String

    var id: String { "\(province)|\(city)" }

    /// 导航栏短标题
    var toolbarTitle: String { city }

    /// 完整省 · 市
    var menuTitle: String { "\(province) · \(city)" }

    /// 与种子数据 `profile.city` / 圈子城市匹配
    func matches(locationText: String) -> Bool {
        locationText.localizedCaseInsensitiveContains(city)
            || locationText.localizedCaseInsensitiveContains(province)
    }
}

enum BuddyCityCatalog {
    static let shanghai = BuddyCityChoice(province: "上海", city: "上海")
    static let `default` = shanghai

    /// 省 → 下属市（演示用常用城市集）
    static let provinces: [(name: String, cities: [String])] = [
        ("上海", ["上海"]),
        ("北京", ["北京"]),
        ("天津", ["天津"]),
        ("重庆", ["重庆"]),
        ("浙江", ["杭州", "宁波", "温州", "嘉兴", "绍兴", "金华"]),
        ("江苏", ["南京", "苏州", "无锡", "常州", "南通", "扬州"]),
        ("广东", ["广州", "深圳", "东莞", "佛山", "珠海", "中山"]),
        ("四川", ["成都", "绵阳", "德阳", "宜宾"]),
        ("湖北", ["武汉", "宜昌", "襄阳"]),
        ("湖南", ["长沙", "株洲", "岳阳"]),
        ("陕西", ["西安", "咸阳", "宝鸡"]),
        ("福建", ["福州", "厦门", "泉州"]),
        ("山东", ["济南", "青岛", "烟台", "潍坊"]),
        ("河南", ["郑州", "洛阳", "开封"]),
        ("安徽", ["合肥", "芜湖", "蚌埠"]),
        ("辽宁", ["沈阳", "大连"]),
        ("云南", ["昆明", "大理"]),
        ("贵州", ["贵阳", "遵义"]),
        ("广西", ["南宁", "桂林", "柳州"]),
        ("江西", ["南昌", "赣州"]),
        ("河北", ["石家庄", "唐山", "保定"]),
        ("山西", ["太原", "大同"]),
        ("黑龙江", ["哈尔滨", "大庆"]),
        ("吉林", ["长春", "吉林"]),
        ("海南", ["海口", "三亚"]),
        ("内蒙古", ["呼和浩特", "包头"]),
        ("新疆", ["乌鲁木齐", "喀什"]),
        ("西藏", ["拉萨"]),
        ("宁夏", ["银川"]),
        ("青海", ["西宁"]),
        ("甘肃", ["兰州", "天水"])
    ]

    static var provinceNames: [String] { provinces.map(\.name) }

    static var all: [BuddyCityChoice] {
        provinces.flatMap { province in
            province.cities.map { BuddyCityChoice(province: province.name, city: $0) }
        }
    }

    static func city(id: String) -> BuddyCityChoice? {
        all.first { $0.id == id }
    }

    static func cities(in province: String) -> [BuddyCityChoice] {
        guard let entry = provinces.first(where: { $0.name == province }) else { return [] }
        return entry.cities.map { BuddyCityChoice(province: province, city: $0) }
    }
}
