// Module: SparkSearch — Live API paths (docs/API_CONTRACT.md).

import Foundation

enum SearchAPIPath {
    static let path = "/v1/search"

    static func search(query: String) -> String? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              !encoded.isEmpty else {
            return nil
        }
        return "\(path)?q=\(encoded)"
    }
}
