// Module: SparkNetworking — Bounded in-memory remote image cache with downsampling.

import UIKit

public struct RemoteImageCacheConfiguration: Sendable {
    public let countLimit: Int
    public let totalCostLimit: Int

    public static let discover = RemoteImageCacheConfiguration(
        countLimit: 24,
        totalCostLimit: 64 * 1_024 * 1_024
    )
    public static let thumbnail = RemoteImageCacheConfiguration(
        countLimit: 128,
        totalCostLimit: 32 * 1_024 * 1_024
    )

    public init(countLimit: Int, totalCostLimit: Int) {
        self.countLimit = countLimit
        self.totalCostLimit = totalCostLimit
    }
}

public actor RemoteImageCache {
    private let httpClient: HTTPClient
    private let memoryCache: NSCache<NSURL, UIImage>
    private var inFlight: [URL: Task<UIImage, Error>] = [:]

    public init(
        httpClient: HTTPClient,
        configuration: RemoteImageCacheConfiguration = .thumbnail
    ) {
        self.httpClient = httpClient
        memoryCache = NSCache()
        memoryCache.countLimit = configuration.countLimit
        memoryCache.totalCostLimit = configuration.totalCostLimit
    }

    /// Preview and test helper wired to the mock API host session.
    public static func previewInstance() -> RemoteImageCache {
        guard let url = URL(string: "https://mock.spark.local") else {
            preconditionFailure("Invalid mock API base URL")
        }
        return RemoteImageCache(httpClient: HTTPClient(configuration: APIConfiguration(baseURL: url)))
    }

    public func image(for url: URL, maxPixelSize: CGFloat = 512) async throws -> UIImage {
        let cacheKey = url as NSURL
        if let cached = memoryCache.object(forKey: cacheKey) {
            return cached
        }
        if let existing = inFlight[url] {
            return try await existing.value
        }

        let task = Task<UIImage, Error> { [httpClient] in
            let data = try await httpClient.fetchData(from: url)
            return try await Task.detached(priority: .utility) {
                try UIImage.downsampled(from: data, maxPixelSize: maxPixelSize)
            }.value
        }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let image = try await task.value
        let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? 0
        memoryCache.setObject(image, forKey: cacheKey, cost: cost)
        return image
    }

    public func clear() {
        memoryCache.removeAllObjects()
        inFlight.removeAll()
    }
}
