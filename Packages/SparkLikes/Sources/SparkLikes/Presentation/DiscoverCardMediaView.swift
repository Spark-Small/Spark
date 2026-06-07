// Module: SparkLikes — Full-bleed card media entry.

import SparkCore
import SwiftUI

struct DiscoverCardMediaView: View {
    let card: DiscoverCard
    let isActive: Bool
    @Bindable var zoomState: DiscoverPhotoZoomState

    var body: some View {
        Group {
            if card.galleryMedia.count > 1 {
                DiscoverCardMediaPager(card: card, isActive: isActive, zoomState: zoomState)
            } else {
                DiscoverSingleMediaView(
                    card: card,
                    media: card.primaryMedia,
                    isActive: isActive,
                    zoomState: zoomState
                )
            }
        }
        .onChange(of: isActive) { _, active in
            if !active {
                zoomState.reset(animated: false)
            }
        }
    }
}

private extension DiscoverCard {
    var primaryMedia: DiscoverMedia {
        galleryMedia[0]
    }
}

#Preview {
    DiscoverCardMediaView(
        card: DiscoverCard(
            userID: UserID("preview"),
            displayName: "Preview",
            bio: "Bio",
            gender: .female,
            media: DiscoverMedia(kind: .image, url: URL(string: "https://example.com/a.jpg")!),
            interestTags: ["咖啡"]
        ),
        isActive: true,
        zoomState: DiscoverPhotoZoomState()
    )
    .environment(\.discoverMediaImageCache, DiscoverMediaImageCache())
    .frame(height: 420)
}
