// Module: SparkLikes — In-memory cache for discover card photos.

import SparkNetworking
import UIKit

enum DiscoverMediaImageError: Error {
    case invalidData
}

public actor DiscoverMediaImageCache {
    private let cache: RemoteImageCache
    private static let maxPixelSize: CGFloat = 1_280

    public init(httpClient: HTTPClient) {
        cache = RemoteImageCache(httpClient: httpClient, configuration: .discover)
    }

    /// Preview and test helper wired to the mock API host session.
    public static func previewInstance() -> DiscoverMediaImageCache {
        guard let url = URL(string: "https://mock.spark.local") else {
            preconditionFailure("Invalid mock API base URL")
        }
        return DiscoverMediaImageCache(httpClient: HTTPClient(configuration: APIConfiguration(baseURL: url)))
    }

    func image(for url: URL) async throws -> UIImage {
        do {
            return try await cache.image(for: url, maxPixelSize: Self.maxPixelSize)
        } catch {
            throw DiscoverMediaImageError.invalidData
        }
    }

    func clear() async {
        await cache.clear()
    }
}
