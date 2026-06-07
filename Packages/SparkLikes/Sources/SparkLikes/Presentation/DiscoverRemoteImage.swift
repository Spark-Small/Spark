// Module: SparkLikes — Remote image display (ambient backdrop + zoomable foreground).

import SparkDesignSystem
import SparkCore
import SwiftUI
import UIKit

enum DiscoverRemoteImagePhase: Equatable {
    case loading
    case loaded(UIImage)
    case failed
}

struct DiscoverRemoteImage: View {
    let url: URL
    let isInteractionEnabled: Bool
    var failureDisplayName: String = ""
    @Bindable var zoomState: DiscoverPhotoZoomState
    @Environment(\.discoverMediaImageCache) private var imageCache

    @State private var phase: DiscoverRemoteImagePhase = .loading
    @State private var fitSize: CGSize = .zero
    @State private var lastDragTranslation: CGSize = .zero
    @State private var magnificationBase: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                switch phase {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .sparkLoadingAccessibilityLabel(
                            String(
                                localized: "likes.photo.loading.a11y",
                                defaultValue: "正在加载照片",
                                comment: "Photo loading"
                            )
                        )
                case .failed:
                    DiscoverMediaPlaceholder(
                        displayName: failureDisplayName,
                        systemImage: "photo",
                        accent: .gray
                    )
                case .loaded(let image):
                    DiscoverAmbientImageBackdrop(image: image)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    foregroundLayer(image: image, container: geometry.size)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .onChange(of: phase) { _, _ in
                fitSize = aspectFitSize(for: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                fitSize = aspectFitSize(for: newSize)
                if zoomState.isZoomed {
                    zoomState.offset = zoomState.boundedOffset(
                        proposed: zoomState.offset,
                        fitSize: fitSize,
                        container: newSize,
                        scale: zoomState.scale
                    )
                }
            }
        }
        .task(id: url) {
            await loadImage()
        }
        .onChange(of: isInteractionEnabled) { _, enabled in
            if !enabled {
                magnificationBase = 1
            } else {
                magnificationBase = zoomState.scale
            }
        }
        .onChange(of: zoomState.scale) { _, scale in
            if scale <= 1.01 {
                magnificationBase = 1
            }
        }
    }

    @ViewBuilder
    private func foregroundLayer(image: UIImage, container: CGSize) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: fitSize.width, height: fitSize.height)
            .scaleEffect(zoomState.scale)
            .offset(zoomState.offset)
            .frame(width: container.width, height: container.height)
            .contentShape(Rectangle())
            .modifier(
                DiscoverPhotoInteractionModifier(
                    isEnabled: isInteractionEnabled,
                    gesture: interactionGestures(container: container),
                    onDoubleTap: {
                        zoomState.toggleDoubleTap(fitSize: fitSize, container: container)
                    }
                )
            )
            .accessibilityLabel(
                String(
                    localized: "likes.photo.foreground.a11y",
                    defaultValue: "推荐照片",
                    comment: "Photo foreground"
                )
            )
            .accessibilityAddTraits(zoomState.isZoomed ? .allowsDirectInteraction : [])
            .accessibilityHint(
                String(
                    localized: "likes.photo.zoom.hint",
                    defaultValue: "双指缩放查看细节，双击还原",
                    comment: "Photo zoom hint"
                )
            )
    }

    private func interactionGestures(container: CGSize) -> some Gesture {
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
                zoomState.offset = zoomState.boundedOffset(
                    proposed: zoomState.offset,
                    fitSize: fitSize,
                    container: container,
                    scale: zoomState.scale
                )
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

    private func aspectFitSize(for container: CGSize) -> CGSize {
        guard case .loaded(let image) = phase else {
            return container
        }
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return container }
        let widthRatio = container.width / imageSize.width
        let heightRatio = container.height / imageSize.height
        let ratio = min(widthRatio, heightRatio)
        return CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
    }

    private func loadImage() async {
        phase = .loading
        if url.scheme == "spark-likes" {
            phase = .failed
            return
        }
        guard let imageCache else {
            phase = .failed
            return
        }
        do {
            let image = try await imageCache.image(for: url)
            guard !Task.isCancelled else { return }
            phase = .loaded(image)
        } catch is CancellationError {
            return
        } catch {
            phase = .failed
        }
    }
}

// REASONING: Double-tap zoom is a media gesture (Photos pattern), not a primary action — keep onTapGesture(count: 2).
private struct DiscoverPhotoInteractionModifier<G: Gesture>: ViewModifier {
    let isEnabled: Bool
    let gesture: G
    let onDoubleTap: () -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content
                .gesture(gesture)
                .onTapGesture(count: 2, perform: onDoubleTap)
        } else {
            content
        }
    }
}

#Preview {
    DiscoverRemoteImage(
        url: MockURL.require("https://example.com/photo.jpg"),
        isInteractionEnabled: true,
        failureDisplayName: "Preview",
        zoomState: DiscoverPhotoZoomState()
    )
    .environment(\.discoverMediaImageCache, DiscoverMediaImageCache.previewInstance())
    .frame(height: 360)
}
