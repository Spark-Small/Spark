//
//  GreetingWeatherConfiguration.swift
//  坐标系
//
//  WeatherKit 接入开关。
//  个人开发队暂不支持 WeatherKit entitlement；企业账号开通能力后：
//  1) 将 `usesWeatherKit` 改为 `true`
//  2) 在 坐标系.entitlements 加回 com.apple.developer.weatherkit = true
//  3) Developer 后台为 App ID 勾选 WeatherKit
//

import Foundation
import CoordinateModels

enum GreetingWeatherConfiguration {
    /// 企业账号 + WeatherKit 能力就绪后改为 `true`。
    static let usesWeatherKit = false
}
