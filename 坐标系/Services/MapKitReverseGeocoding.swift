//
//  MapKitReverseGeocoding.swift
//  坐标系
//
//  iOS 26+：用 MapKit `MKReverseGeocodingRequest` 替代已弃用的 CLGeocoder。
//  写法对齐 Apple 文档示例（await request.mapItems → MKMapItem）。
//

import MapKit
import CoordinateModels

enum MapKitReverseGeocoding {
    /// 官方：`MKReverseGeocodingRequest(location:)` → `await mapItems`
    static func mapItem(for location: CLLocation) async -> MKMapItem? {
        guard let request = MKReverseGeocodingRequest(location: location) else { return nil }
        return try? await request.mapItems.first
    }

    /// 天气顶栏等地名：优先 `addressRepresentations.cityName`
    static func placeName(for location: CLLocation) async -> String? {
        guard let mapItem = await mapItem(for: location) else { return nil }
        if let city = mapItem.addressRepresentations?.cityName, !city.isEmpty {
            return city
        }
        if let short = mapItem.address?.shortAddress, !short.isEmpty {
            return short
        }
        if let name = mapItem.name, !name.isEmpty {
            return name
        }
        return nil
    }

    /// 地图选点等展示用地址文案
    static func addressLabel(for location: CLLocation) async -> String? {
        guard let mapItem = await mapItem(for: location) else { return nil }
        if let short = mapItem.address?.shortAddress, !short.isEmpty {
            return short
        }
        if let full = mapItem.address?.fullAddress, !full.isEmpty {
            return full
        }
        if let name = mapItem.name, !name.isEmpty {
            return name
        }
        return nil
    }

    static func addressLabel(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return await addressLabel(for: location)
    }
}
