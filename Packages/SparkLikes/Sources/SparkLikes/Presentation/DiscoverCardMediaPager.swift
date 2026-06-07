// Module: SparkLikes — Horizontal photo gallery (Photos-style paging).

import AVKit
import SparkCore
import SwiftUI
import UIKit

struct DiscoverCardMediaPager: View {
    let card: DiscoverCard
    let isActive: Bool
    @Bindable var zoomState: DiscoverPhotoZoomState

    @State private var pageIndex = 0

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $pageIndex) {
                ForEach(Array(card.galleryMedia.enumerated()), id: \.element.url) { index, media in
                    DiscoverSingleMediaView(
                        card: card,
                        media: media,
                        isActive: isActive && pageIndex == index,
                        zoomState: zoomState
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            if card.galleryMedia.count > 1 {
                HStack(spacing: 4) {
                    ForEach(Array(card.galleryMedia.enumerated()), id: \.offset) { index, _ in
                        Capsule()
                            .fill(index == pageIndex ? Color.primary : Color.secondary.opacity(0.35))
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .accessibilityLabel(galleryPageAccessibilityLabel)
            }
        }
        .onChange(of: isActive) { _, active in
            if !active {
                pageIndex = 0
                zoomState.reset(animated: false)
            }
        }
    }

    private var galleryPageAccessibilityLabel: String {
        let format = String(
            localized: "likes.gallery.page.format",
            defaultValue: "第 %1$d 张，共 %2$d 张",
            comment: "Gallery page indicator"
        )
        return String(format: format, locale: .current, pageIndex + 1, card.galleryMedia.count)
    }
}

struct DiscoverSingleMediaView: View {
    let card: DiscoverCard
    let media: DiscoverMedia
    let isActive: Bool
    @Bindable var zoomState: DiscoverPhotoZoomState

    var body: some View {
        Group {
            if media.url.scheme == "spark-likes" {
                mockPlaceholder
            } else if media.kind == .video {
                videoLayer
            } else {
                DiscoverRemoteImage(
                    url: media.url,
                    isInteractionEnabled: isActive,
                    failureDisplayName: card.displayName,
                    zoomState: zoomState
                )
            }
        }
        .preference(
            key: DiscoverPhotoZoomedPreferenceKey.self,
            value: isActive && zoomState.isZoomed
        )
    }

    @ViewBuilder
    private var mockPlaceholder: some View {
        let colors: [Color] = [.blue, .purple, .orange, .teal]
        let index = abs(card.id.hashValue &+ media.url.hashValue) % colors.count
        if isActive, media.kind == .image {
            DiscoverMockZoomablePhoto(
                accent: colors[index],
                displayName: card.displayName,
                systemImage: "person.fill",
                zoomState: zoomState
            )
        } else {
            DiscoverMediaPlaceholder(
                displayName: card.displayName,
                systemImage: media.kind == .video ? "play.circle.fill" : "person.fill",
                accent: colors[index]
            )
        }
    }

    @ViewBuilder
    private var videoLayer: some View {
        ZStack {
            if let posterURL = media.posterURL {
                DiscoverRemoteImage(
                    url: posterURL,
                    isInteractionEnabled: false,
                    zoomState: zoomState
                )
                .allowsHitTesting(false)
            } else {
                Color.black
            }
            if isActive {
                DiscoverVideoSurfaceView(url: media.url)
            } else {
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }
}

// REASONING: Shared with DiscoverCardMediaView for mock zoom on multi-photo cards.
struct DiscoverMockZoomablePhoto: View {
    let accent: Color
    let displayName: String
    let systemImage: String
    @Bindable var zoomState: DiscoverPhotoZoomState

    @State private var lastDragTranslation: CGSize = .zero
    @State private var magnificationBase: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            let fit = CGSize(
                width: geometry.size.width * 0.82,
                height: geometry.size.height * 0.62
            )
            ZStack {
                Rectangle()
                    .fill(accent.gradient)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                Color(.tertiarySystemFill)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                VStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                    Text(displayName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: fit.width, height: fit.height)
                .scaleEffect(zoomState.scale)
                .offset(zoomState.offset)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .contentShape(Rectangle())
                .gesture(zoomGestures(fitSize: fit, container: geometry.size))
                // REASONING: Photos-style double-tap zoom; not a primary action — use gesture, not Button.
                .onTapGesture(count: 2) {
                    zoomState.toggleDoubleTap(fitSize: fit, container: geometry.size)
                }
                .accessibilityLabel(
                    String(
                        localized: "likes.photo.foreground.a11y",
                        defaultValue: "推荐照片",
                        comment: "Photo foreground"
                    )
                )
                .accessibilityHint(
                    String(
                        localized: "likes.photo.zoom.hint",
                        defaultValue: "双指缩放查看细节，双击还原",
                        comment: "Photo zoom hint"
                    )
                )
            }
            .clipped()
        }
    }

    private func zoomGestures(fitSize: CGSize, container: CGSize) -> some Gesture {
        let magnification = MagnifyGesture()
            .onChanged { value in
                zoomState.applyMagnification(
                    baseScale: magnificationBase,
                    magnification: value.magnification,
                    fitSize: fitSize,
                    container: container
                )
            }
            .onEnded { _ in
                magnificationBase = zoomState.scale
            }
        let drag = DragGesture()
            .onChanged { value in
                let delta = CGSize(
                    width: value.translation.width - lastDragTranslation.width,
                    height: value.translation.height - lastDragTranslation.height
                )
                lastDragTranslation = value.translation
                zoomState.applyDrag(translation: delta, fitSize: fitSize, container: container)
            }
            .onEnded { _ in
                lastDragTranslation = .zero
            }
        return magnification.simultaneously(with: drag)
    }
}

struct DiscoverVideoSurfaceView: View {
    let url: URL
    @State private var isPlaying = true

    var body: some View {
        DiscoverVideoPlayerRepresentable(url: url, isPlaying: isPlaying)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            // REASONING: Full-bleed video — tap toggles playback like system players; not a labeled button.
            .onTapGesture {
                isPlaying.toggle()
            }
            .accessibilityLabel(
                String(localized: "likes.video.a11y", defaultValue: "推荐视频", comment: "Video")
            )
            .accessibilityHint(
                String(
                    localized: "likes.video.tap.hint",
                    defaultValue: "点按暂停或继续播放",
                    comment: "Video tap hint"
                )
            )
            .accessibilityAddTraits(.startsMediaSession)
    }
}

struct DiscoverVideoPlayerRepresentable: UIViewRepresentable {
    let url: URL
    let isPlaying: Bool

    func makeUIView(context: Context) -> DiscoverPlayerUIView {
        let view = DiscoverPlayerUIView()
        view.configure(url: url)
        return view
    }

    func updateUIView(_ uiView: DiscoverPlayerUIView, context: Context) {
        if isPlaying {
            uiView.play()
        } else {
            uiView.pause()
        }
    }

    static func dismantleUIView(_ uiView: DiscoverPlayerUIView, coordinator: ()) {
        uiView.teardown()
    }
}

@MainActor
final class DiscoverPlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    func configure(url: URL) {
        guard url.scheme != "spark-likes" else { return }
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect
        self.layer.addSublayer(layer)
        playerLayer = layer
        self.player = player
        player.play()
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func teardown() {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
    }
}

private extension DiscoverCard {
    static var previewCard: DiscoverCard {
        DiscoverCard(
            userID: UserID("preview"),
            displayName: "Preview",
            bio: "Bio",
            gender: .female,
            media: DiscoverMedia(kind: .image, url: MockURL.require("https://example.com/a.jpg")),
            mediaItems: [
                DiscoverMedia(kind: .image, url: MockURL.require("https://example.com/a.jpg")),
                DiscoverMedia(kind: .image, url: MockURL.require("https://example.com/b.jpg"))
            ],
            interestTags: ["咖啡"]
        )
    }
}

#Preview("Media pager") {
    DiscoverCardMediaPager(
        card: .previewCard,
        isActive: true,
        zoomState: DiscoverPhotoZoomState()
    )
    .environment(\.discoverMediaImageCache, DiscoverMediaImageCache.previewInstance())
    .frame(height: 420)
}
