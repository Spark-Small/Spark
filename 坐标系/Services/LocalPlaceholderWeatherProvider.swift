//
//  LocalPlaceholderWeatherProvider.swift
//  坐标系
//
//  个人开发账号占位实现：仍走系统定位 + MapKit 逆地理，天气文案本地推演。
//  与 WeatherKit 返回同一 `WeatherSnapshot`，切换后端时 UI 不变。
//

import CoreLocation
import Foundation

struct LocalPlaceholderWeatherProvider: WeatherProviding {
    func fetchCurrent(at location: CLLocation) async throws -> WeatherSnapshot {
        let place = await MapKitReverseGeocoding.placeName(for: location)
        let seeded = Self.seededReading(coordinate: location.coordinate, date: .now)

        // 埋点预留：占位阶段可上报 weather_fetch_placeholder，便于后期对比切换前后。
        // Analytics.track("weather_fetch", ["source": "localPlaceholder"])

        return WeatherSnapshot(
            temperatureC: seeded.temperatureC,
            conditionText: seeded.conditionText,
            systemImage: seeded.systemImage,
            placeName: place,
            legalAttributionURL: nil,
            source: .localPlaceholder
        )
    }

    /// 活动日天气预报（按活动日期 + 坐标/地点种子），供详情头图展示。
    static func forecast(for activity: Activity) -> (temperatureC: Int, conditionText: String, systemImage: String) {
        let coordinate: CLLocationCoordinate2D = {
            if let lat = activity.latitude, let lon = activity.longitude {
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            var hasher = Hasher()
            hasher.combine(activity.location)
            let seed = abs(hasher.finalize())
            return CLLocationCoordinate2D(
                latitude: 31.2 + Double(seed % 80) / 1000,
                longitude: 121.4 + Double((seed / 80) % 80) / 1000
            )
        }()
        return seededReading(coordinate: coordinate, date: activity.date)
    }

    static func seededReading(
        coordinate: CLLocationCoordinate2D,
        date: Date
    ) -> (temperatureC: Int, conditionText: String, systemImage: String) {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let hour = Calendar.current.component(.hour, from: date)
        var hasher = Hasher()
        hasher.combine(Int(coordinate.latitude * 1000))
        hasher.combine(Int(coordinate.longitude * 1000))
        hasher.combine(day)
        let seed = abs(hasher.finalize())

        let base = 18 + (seed % 12)
        let temp: Int = {
            switch hour {
            case 0..<6: return base - 3
            case 6..<11: return base - 1
            case 11..<17: return base + 2
            default: return base
            }
        }()

        let presets: [(String, String)] = [
            ("晴", "sun.max"),
            ("多云", "cloud.sun"),
            ("微风", "wind"),
            ("阴", "cloud"),
            ("小雨", "cloud.drizzle")
        ]
        let pick = presets[seed % presets.count]
        return (temp, pick.0, pick.1)
    }
}
