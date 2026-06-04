// Module: SparkSearch — Search API payloads.

import Foundation

struct SearchResponseDTO: Decodable, Sendable {
    let results: [SearchResultItemDTO]
}

struct SearchResultItemDTO: Decodable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let kind: String
}
