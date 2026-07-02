// Module: SparkActivity — Open venue in Maps (display name only, no stored coordinates).

import Foundation

enum ActivityMapProvider: CaseIterable, Identifiable {
    case appleMaps
    case amap
    case googleMaps

    var id: Self { self }

    var localizedLabel: String {
        switch self {
        case .appleMaps:
            String(localized: "activity.map.provider.apple", defaultValue: "地图", comment: "Apple Maps")
        case .amap:
            String(localized: "activity.map.provider.amap", defaultValue: "高德地图", comment: "Amap")
        case .googleMaps:
            String(localized: "activity.map.provider.google", defaultValue: "Google 地图", comment: "Google Maps")
        }
    }

    func url(locationName: String, directions: Bool) -> URL? {
        switch self {
        case .appleMaps:
            directions ? ActivityMapURL.directionsURL(locationName: locationName) : ActivityMapURL.mapsURL(locationName: locationName)
        case .amap:
            ActivityMapURL.amapURL(locationName: locationName, directions: directions)
        case .googleMaps:
            ActivityMapURL.googleMapsURL(locationName: locationName, directions: directions)
        }
    }
}

enum ActivityMapURL {
    static func mapsURL(locationName: String) -> URL? {
        url(queryKey: "q", locationName: locationName)
    }

    /// Turn-by-turn directions in Apple Maps (`daddr` = destination).
    static func directionsURL(locationName: String) -> URL? {
        url(queryKey: "daddr", locationName: locationName)
    }

    /// Driving directions — used for one-tap navigation / ride entry when coordinates are unavailable.
    static func rideHailingURL(locationName: String) -> URL? {
        guard let encoded = encodedQuery(locationName) else { return nil }
        if let amap = URL(string: "iosamap://path?sourceApplication=Spark&dname=\(encoded)&dev=0&t=0") {
            return amap
        }
        return URL(string: "http://maps.apple.com/?daddr=\(encoded)&dirflg=d")
    }

    static func amapURL(locationName: String, directions: Bool) -> URL? {
        guard let encoded = encodedQuery(locationName) else { return nil }
        if directions {
            return URL(string: "iosamap://path?sourceApplication=Spark&dname=\(encoded)&dev=0&t=0")
        }
        return URL(string: "iosamap://poi?sourceApplication=Spark&name=\(encoded)")
            ?? URL(string: "https://uri.amap.com/search?keyword=\(encoded)")
    }

    static func googleMapsURL(locationName: String, directions: Bool) -> URL? {
        guard let encoded = encodedQuery(locationName) else { return nil }
        if directions {
            return URL(string: "comgooglemaps://?daddr=\(encoded)&directionsmode=driving")
                ?? URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(encoded)")
        }
        return URL(string: "comgooglemaps://?q=\(encoded)")
            ?? URL(string: "https://www.google.com/maps/search/?api=1&query=\(encoded)")
    }

    private static func url(queryKey: String, locationName: String) -> URL? {
        guard let encoded = encodedQuery(locationName) else { return nil }
        return URL(string: "http://maps.apple.com/?\(queryKey)=\(encoded)")
    }

    private static func encodedQuery(_ locationName: String) -> String? {
        let trimmed = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }
}
