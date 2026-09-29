//
//  LocationService.swift
//  坐标系
//

import CoreLocation
import Foundation
import Observation
import CoordinateModels

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    static var shared: LocationService { AppComposition.locationService }

    private let manager = CLLocationManager()
    private(set) var authorization: CLAuthorizationStatus
    private(set) var coordinate: CLLocationCoordinate2D?
    private(set) var lastError: String?

    /// 已获得定位授权（使用期间或始终）
    var isAuthorized: Bool {
        syncAuthorization()
        switch authorization {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    /// 供 SwiftUI `.task(id:)` 观察授权 / 坐标变化
    var observationToken: String {
        syncAuthorization()
        let lat = coordinate?.latitude ?? 0
        let lon = coordinate?.longitude ?? 0
        return "\(authorization.rawValue)-\(lat)-\(lon)"
    }

    /// 系统是否还可能弹出「使用期间」授权框（仅 notDetermined）
    var canPromptWhenInUse: Bool {
        syncAuthorization()
        return authorization == .notDetermined
    }

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func syncAuthorization() {
        authorization = manager.authorizationStatus
    }

    /// 仅在 `.notDetermined` 时弹出系统授权框。
    /// 已允许 / 已拒绝时系统不会再弹（与是否重新登录无关）。
    func requestWhenInUse() {
        syncAuthorization()
        guard authorization == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    /// 进入主界面后调用：等窗口稳定再请求，避免登录转场时弹窗被吃掉
    func promptWhenInUseIfNeeded() {
        syncAuthorization()
        guard authorization == .notDetermined else {
            if authorization == .authorizedWhenInUse || authorization == .authorizedAlways {
                refresh()
            }
            return
        }
        Task { @MainActor in
            // 等 Tab / Navigation 完成呈现后再弹系统框
            try? await Task.sleep(for: .milliseconds(450))
            syncAuthorization()
            guard authorization == .notDetermined else { return }
            manager.requestWhenInUseAuthorization()
        }
    }

    func refresh() {
        syncAuthorization()
        switch authorization {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        default:
            break
        }
    }

    func distanceKM(to latitude: Double, longitude: Double) -> Double? {
        guard let coordinate else { return nil }
        let from = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let to = CLLocation(latitude: latitude, longitude: longitude)
        return from.distance(from: to) / 1000
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorization = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        Task { @MainActor in
            self.coordinate = coordinate
            lastError = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let message = error.localizedDescription
        Task { @MainActor in
            lastError = message
        }
    }
}
