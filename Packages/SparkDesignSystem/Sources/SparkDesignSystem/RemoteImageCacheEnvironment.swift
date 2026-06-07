// Module: SparkDesignSystem — Environment injection for shared remote image cache.

import SparkNetworking
import SwiftUI

private struct RemoteImageCacheKey: EnvironmentKey {
    static let defaultValue: RemoteImageCache? = nil
}

extension EnvironmentValues {
    public var remoteImageCache: RemoteImageCache? {
        get { self[RemoteImageCacheKey.self] }
        set { self[RemoteImageCacheKey.self] = newValue }
    }
}
