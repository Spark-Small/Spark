//
//  ProfileZodiac.swift
//  CoordinateModels
//
//  十二星座：可选手选；有出生日期时由公历推导（实名后更准）。
//

import Foundation

public enum ProfileZodiac: String, Codable, CaseIterable, Hashable, Sendable, Identifiable {
    case capricorn = "摩羯座"
    case aquarius = "水瓶座"
    case pisces = "双鱼座"
    case aries = "白羊座"
    case taurus = "金牛座"
    case gemini = "双子座"
    case cancer = "巨蟹座"
    case leo = "狮子座"
    case virgo = "处女座"
    case libra = "天秤座"
    case scorpio = "天蝎座"
    case sagittarius = "射手座"

    public var id: String { rawValue }

    /// 公历月日 → 星座（热带黄道常用分界）。
    public static func from(birthDate: Date, calendar: Calendar = Calendar(identifier: .gregorian)) -> ProfileZodiac {
        let month = calendar.component(.month, from: birthDate)
        let day = calendar.component(.day, from: birthDate)
        switch (month, day) {
        case (1, 1...19), (12, 22...31): return .capricorn
        case (1, 20...31), (2, 1...18): return .aquarius
        case (2, 19...29), (3, 1...20): return .pisces
        case (3, 21...31), (4, 1...19): return .aries
        case (4, 20...30), (5, 1...20): return .taurus
        case (5, 21...31), (6, 1...21): return .gemini
        case (6, 22...30), (7, 1...22): return .cancer
        case (7, 23...31), (8, 1...22): return .leo
        case (8, 23...31), (9, 1...22): return .virgo
        case (9, 23...30), (10, 1...23): return .libra
        case (10, 24...31), (11, 1...22): return .scorpio
        case (11, 23...30), (12, 1...21): return .sagittarius
        default: return .capricorn
        }
    }
}
