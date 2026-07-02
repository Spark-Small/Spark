// Module: SparkActivity — Shared cover image (list + detail).

import SparkDesignSystem
import SwiftUI
import UIKit

struct ActivityCoverHeroView: View {
    let activityID: String
    let title: String
    var coverURL: URL?
    var coverPosterURL: URL?
    var coverIsVideo: Bool = false
    var appliesCornerClip: Bool
    var onCoverImageLoaded: ((UIImage) -> Void)?

    init(
        activityID: String,
        title: String,
        coverURL: URL? = nil,
        coverPosterURL: URL? = nil,
        coverIsVideo: Bool = false,
        appliesCornerClip: Bool = true,
        onCoverImageLoaded: ((UIImage) -> Void)? = nil
    ) {
        self.activityID = activityID
        self.title = title
        self.coverURL = coverURL
        self.coverPosterURL = coverPosterURL
        self.coverIsVideo = coverIsVideo
        self.appliesCornerClip = appliesCornerClip
        self.onCoverImageLoaded = onCoverImageLoaded
    }

    var body: some View {
        SparkCachedRemoteImage(
            url: ActivityCoverImage.url(
                activityID: activityID,
                coverURL: coverURL,
                coverPosterURL: coverPosterURL,
                coverIsVideo: coverIsVideo
            ),
            maxPixelSize: 800,
            onImageLoaded: onCoverImageLoaded,
            content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            },
            placeholder: {
                heroPlaceholder
            }
        )
        .frame(maxWidth: .infinity)
        .aspectRatio(SparkLayoutMetrics.activityCardHeroAspectRatio, contentMode: .fill)
        .modifier(ActivityCoverHeroClipModifier(appliesCornerClip: appliesCornerClip))
        .overlay {
            if coverIsVideo {
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityHidden(true)
    }

    private var heroPlaceholder: some View {
        RoundedRectangle(cornerRadius: SparkLayoutMetrics.activityCardHeroCornerRadius, style: .continuous)
            .fill(.quaternary)
            .overlay {
                Image(systemName: coverIsVideo ? "video.fill" : "photo")
                    .font(.title2)
                    .foregroundStyle(.tertiary)
            }
    }
}

private struct ActivityCoverHeroClipModifier: ViewModifier {
    let appliesCornerClip: Bool

    func body(content: Content) -> some View {
        if appliesCornerClip {
            content.clipShape(
                RoundedRectangle(
                    cornerRadius: SparkLayoutMetrics.activityCardHeroCornerRadius,
                    style: .continuous
                )
            )
        } else {
            content
        }
    }
}

#Preview("List hero") {
    ActivityCoverHeroView(activityID: "act_1", title: "周末徒步")
        .padding()
}
