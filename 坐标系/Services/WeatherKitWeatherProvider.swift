//
//  WeatherKitWeatherProvider.swift
//  坐标系
//
//  正式 WeatherKit 实现。个人账号阶段 `usesWeatherKit == false` 不会走到这里；
//  企业账号开通后打开开关即可接入，无需改 UI。
//

import CoreLocation
import Foundation
import WeatherKit
import CoordinateModels

struct WeatherKitWeatherProvider: WeatherProviding {
    func fetchCurrent(at location: CLLocation) async throws -> WeatherSnapshot {
        async let weatherTask = WeatherService.shared.weather(for: location)
        async let placeTask = MapKitReverseGeocoding.placeName(for: location)
        async let attributionTask = WeatherService.shared.attribution

        let weather = try await weatherTask
        let place = await placeTask
        let attribution = try? await attributionTask

        let current = weather.currentWeather
        let celsius = current.temperature.converted(to: .celsius).value

        // 埋点预留：正式接入后可在此上报 weather_fetch_success / latency 等。
        // Analytics.track("weather_fetch", ["source": "weatherKit", "condition": current.condition.rawValue])

        return WeatherSnapshot(
            temperatureC: Int(celsius.rounded()),
            conditionText: current.condition.description,
            systemImage: current.symbolName,
            placeName: place,
            legalAttributionURL: attribution?.legalPageURL,
            source: .weatherKit
        )
    }
}
