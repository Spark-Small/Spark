// Module: SparkCommunity — Swipeable post gallery (photos + videos).

import AVKit
import SparkCore
import SparkDesignSystem
import SwiftUI

struct CommunityPostMediaPager: View {
    let mediaItems: [SparkGalleryMedia]
    let usesInsetMedia: Bool
    let horizontalPadding: CGFloat
    let onOpen: () -> Void

    @State private var pageIndex = 0

    var body: some View {
        TabView(selection: $pageIndex) {
            ForEach(Array(mediaItems.enumerated()), id: \.element.id) { index, media in
                CommunityPostSingleMediaView(
                    media: media,
                    isActive: pageIndex == index,
                    usesInsetMedia: usesInsetMedia,
                    horizontalPadding: horizontalPadding
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .aspectRatio(4 / 5, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(galleryAccessibilityLabel)
    }

    private var galleryAccessibilityLabel: String {
        let format = String(
            localized: "community.gallery.page.format",
            defaultValue: "媒体 %1$d / %2$d",
            comment: "Gallery page; index and total"
        )
        return String(format: format, locale: .current, pageIndex + 1, mediaItems.count)
    }
}

private struct CommunityPostSingleMediaView: View {
    let media: SparkGalleryMedia
    let isActive: Bool
    let usesInsetMedia: Bool
    let horizontalPadding: CGFloat

    var body: some View {
        Group {
            if media.kind == .video {
                videoLayer
            } else {
                imageLayer
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(clipShape)
        .padding(.horizontal, usesInsetMedia ? horizontalPadding : 0)
    }

    private var imageLayer: some View {
        SparkCachedRemoteImage(
            url: media.url,
            maxPixelSize: 1_280,
            content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            },
            placeholder: {
                Color(.tertiarySystemFill)
            }
        )
        .clipped()
    }

    @ViewBuilder
    private var videoLayer: some View {
        ZStack {
            if let posterURL = media.posterURL {
                SparkCachedRemoteImage(
                    url: posterURL,
                    maxPixelSize: 1_280,
                    content: { image in
                        image.resizable().scaledToFill().accessibilityHidden(true)
                    },
                    placeholder: {
                        Color(.tertiarySystemFill)
                    }
                )
                .allowsHitTesting(false)
            } else {
                Color(.tertiarySystemFill)
            }
            if isActive {
                CommunityInlineVideoPlayer(url: media.url)
            } else {
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
            }
        }
        .clipped()
    }

    private var clipShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: usesInsetMedia ? SparkLayoutMetrics.sparkCardCornerRadius : 0,
            style: .continuous
        )
    }
}

private struct CommunityInlineVideoPlayer: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: url)
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {}

    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: ()) {
        controller.player?.pause()
        controller.player = nil
    }
}

#Preview {
    CommunityPreviewTraits.matrix("Post media pager") {
        CommunityPostMediaPager(
            mediaItems: SparkGalleryMediaFactory.mockActivityGallery(activityID: "act_preview"),
            usesInsetMedia: false,
            horizontalPadding: SparkLayoutMetrics.standardHorizontalPadding,
            onOpen: {}
        )
    }
}
