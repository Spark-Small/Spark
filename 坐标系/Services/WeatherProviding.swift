//
//  WeatherProviding.swift
//  坐标系
//
//  天气数据源协议：UI / Store 只依赖此接口，便于后期切换 WeatherKit。
//

import CoreLocation
import Foundation

protocol WeatherProviding: Sendable {
    /// 按坐标拉取实况；`legalAttributionURL` 仅 WeatherKit 需要展示归属。
    func fetchCurrent(at location: CLLocation) async throws -> WeatherSnapshot
}

struct WeatherSnapshot: Equatable, Sendable {
    let temperatureC: Int
    let conditionText: String
    let systemImage: String
    let placeName: String?
    let legalAttributionURL: URL?
    /// 埋点：数据来源，便于后期分析 / 调试。
    let source: Source

    enum Source: String, Equatable, Sendable {
        case weatherKit
        /// 个人账号阶段占位（定位 + 本地推演），非线上实况。
        case localPlaceholder
    }
}
