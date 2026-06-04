// Module: SparkActivity — Open venue in Maps (display name only, no stored coordinates).

import Foundation

enum ActivityMapURL {
    static func mapsURL(locationName: String) -> URL? {
        let trimmed = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "http://maps.apple.com/?q=\(encoded)")
    }
}
