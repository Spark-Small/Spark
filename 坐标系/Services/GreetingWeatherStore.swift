//
//  GreetingWeatherStore.swift
//  坐标系
//
//  定位天气：WeatherProviding；活动 / 搭子顶栏共用 GreetingWeatherStore。
//  当前默认本地占位；企业账号开通 WeatherKit 后只改 GreetingWeatherConfiguration。
//

import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class GreetingWeatherStore {
    static let shared = GreetingWeatherStore()

    enum Status: Equatable {
        case idle
        case loading
        case ready
        case needsLocation
        case failed
    }

    struct Reading: Equatable {
        let temperatureC: Int
        let conditionText: String
        let systemImage: String
        let placeName: String?
        let source: WeatherSnapshot.Source

        var line: String {
            var parts: [String] = []
            if let placeName, !placeName.isEmpty {
                parts.append(placeName)
            } else {
                parts.append("当前位置")
            }
            parts.append("\(temperatureC)°")
            parts.append(conditionText)
            return parts.joined(separator: " · ")
        }

        var accessibilityLabel: String {
            let place = (placeName?.isEmpty == false) ? placeName! : "当前位置"
            return "\(place)，\(temperatureC) 摄氏度，\(conditionText)"
        }
    }

    private(set) var status: Status = .idle
    private(set) var reading: Reading?
    private(set) var legalAttributionURL: URL?

    private var lastFetchedCoordinate: CLLocationCoordinate2D?
    private var lastFetchedAt: Date?

    private init() {}

    /// 顶栏 / 问候用：系统 Label 标题
    var statusTitle: String {
        switch status {
        case .failed:
            return "天气暂不可用"
        case .needsLocation:
            return "定位未开启"
        case .ready:
            return reading?.line ?? "定位中"
        case .loading, .idle:
            return "定位中"
        }
    }

    /// Photos 顶栏中间胶囊：主行（地点 / 状态）
    var statusToolbarPrimary: String {
        switch status {
        case .failed:
            return "天气"
        case .needsLocation:
            return "定位"
        case .ready:
            if let place = reading?.placeName, !place.isEmpty {
                return place
            }
            return reading?.conditionText ?? "天气"
        case .loading, .idle:
            return "定位中"
        }
    }

    /// Photos 顶栏中间胶囊：次行（温度 / 说明）
    var statusToolbarSecondary: String {
        switch status {
        case .failed:
            return "暂不可用"
        case .needsLocation:
            return "未开启"
        case .ready:
            guard let reading else { return "—" }
            return "\(reading.temperatureC)°"
        case .loading, .idle:
            return "…"
        }
    }

    /// 顶栏 / 问候用：系统 Label 符号
    var statusSymbol: String {
        switch status {
        case .ready:
            return reading?.systemImage ?? "cloud.sun"
        case .failed:
            return "exclamationmark.triangle"
        default:
            return "location"
        }
    }

    var statusAccessibilityLabel: String {
        switch status {
        case .failed:
            return "暂时无法获取天气"
        case .needsLocation:
            return "尚未开启定位"
        case .ready:
            guard let reading else { return "正在获取定位与天气" }
            if reading.source == .weatherKit {
                return reading.accessibilityLabel + "，天气数据来自 Apple Weather"
            }
            return reading.accessibilityLabel
        default:
            return "正在获取定位与天气"
        }
    }

    /// 数据源埋点入口：切换 WeatherKit 只换 provider，不改调用方。
    private var provider: any WeatherProviding {
        if GreetingWeatherConfiguration.usesWeatherKit {
            WeatherKitWeatherProvider()
        } else {
            LocalPlaceholderWeatherProvider()
        }
    }

    func refresh(force: Bool = false) async {
        let locationService = LocationService.shared
        locationService.refresh()

        switch locationService.authorization {
        case .notDetermined:
            status = .loading
            locationService.requestWhenInUse()
            // 等系统授权弹窗结果（由 LocationService delegate 更新 authorization）
            for _ in 0..<20 {
                if locationService.authorization != .notDetermined { break }
                try? await Task.sleep(for: .milliseconds(250))
            }
            if locationService.authorization == .notDetermined {
                status = .needsLocation
                return
            }
            if locationService.authorization == .denied
                || locationService.authorization == .restricted {
                status = .needsLocation
                reading = nil
                return
            }

        case .denied, .restricted:
            status = .needsLocation
            reading = nil
            return

        default:
            break
        }

        var coordinate = locationService.coordinate
        if coordinate == nil {
            status = .loading
            locationService.refresh()
            for _ in 0..<16 {
                try? await Task.sleep(for: .milliseconds(250))
                coordinate = locationService.coordinate
                if coordinate != nil { break }
            }
        }

        guard let coordinate else {
            status = .needsLocation
            return
        }

        if !force,
           let last = lastFetchedCoordinate,
           let at = lastFetchedAt,
           Date().timeIntervalSince(at) < 10 * 60,
           hypot(last.latitude - coordinate.latitude, last.longitude - coordinate.longitude) < 0.01,
           reading != nil {
            status = .ready
            return
        }

        status = .loading
        let clLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let startedAt = Date()

        do {
            let snapshot = try await provider.fetchCurrent(at: clLocation)
            reading = Reading(
                temperatureC: snapshot.temperatureC,
                conditionText: snapshot.conditionText,
                systemImage: snapshot.systemImage,
                placeName: snapshot.placeName,
                source: snapshot.source
            )
            legalAttributionURL = snapshot.legalAttributionURL
            lastFetchedCoordinate = coordinate
            lastFetchedAt = .now
            status = .ready

            // 埋点预留：成功
            // Analytics.track("weather_refresh_success", [
            //   "source": snapshot.source.rawValue,
            //   "latency_ms": Int(Date().timeIntervalSince(startedAt) * 1000)
            // ])
            _ = startedAt
        } catch {
            status = .failed
            // 埋点预留：Analytics.track("weather_refresh_failed", ["error": error.localizedDescription])
            _ = startedAt
        }
    }
}
