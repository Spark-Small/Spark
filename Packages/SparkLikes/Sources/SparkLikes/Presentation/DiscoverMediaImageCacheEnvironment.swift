// Module: SparkLikes — DI for discover photo cache (composition root injects one instance).

import SwiftUI

private struct DiscoverMediaImageCacheKey: EnvironmentKey {
    static let defaultValue = DiscoverMediaImageCache()
}

extension EnvironmentValues {
    var discoverMediaImageCache: DiscoverMediaImageCache {
        get { self[DiscoverMediaImageCacheKey.self] }
        set { self[DiscoverMediaImageCacheKey.self] = newValue }
    }
}
