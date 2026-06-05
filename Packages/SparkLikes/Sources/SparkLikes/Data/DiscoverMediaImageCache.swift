// Module: SparkLikes — In-memory cache for discover card photos.

import UIKit

enum DiscoverMediaImageError: Error {
    case invalidData
}

public actor DiscoverMediaImageCache {
    private var storage: [URL: UIImage] = [:]

    public init() {}

    func image(for url: URL) async throws -> UIImage {
        if let cached = storage[url] {
            return cached
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw DiscoverMediaImageError.invalidData
        }
        storage[url] = image
        return image
    }

    func clear() {
        storage.removeAll()
    }
}
