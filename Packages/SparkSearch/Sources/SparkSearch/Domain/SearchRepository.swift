// Module: SparkSearch — Search data boundary.

import Foundation

public protocol SearchRepository: Sendable {
    func search(query: String) async throws -> [SearchResultItem]
}
