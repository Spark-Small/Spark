// Module: SparkDesignSystem — Cached remote image view backed by RemoteImageCache.

import SparkNetworking
import UIKit
import SwiftUI

public struct SparkCachedRemoteImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let maxPixelSize: CGFloat
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @Environment(\.remoteImageCache) private var cache
    @State private var loadedImage: UIImage?

    public init(
        url: URL?,
        maxPixelSize: CGFloat = 512,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.maxPixelSize = maxPixelSize
        self.content = content
        self.placeholder = placeholder
    }

    public var body: some View {
        Group {
            if let loadedImage {
                content(Image(uiImage: loadedImage))
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            loadedImage = nil
            guard let url, let cache else { return }
            loadedImage = try? await cache.image(for: url, maxPixelSize: maxPixelSize)
        }
    }
}

#Preview("Cached avatar") {
    SparkCachedRemoteImage(
        url: URL(string: "https://mock.spark.local/avatar.jpg"),
        maxPixelSize: 512,
        content: { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
        },
        placeholder: {
            Circle()
                .fill(.tertiary)
                .frame(width: 44, height: 44)
        }
    )
    .environment(\.remoteImageCache, RemoteImageCache.previewInstance())
}
