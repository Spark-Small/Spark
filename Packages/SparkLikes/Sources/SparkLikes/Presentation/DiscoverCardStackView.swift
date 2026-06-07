// Module: SparkLikes — Swipeable card stack with pass/like/profile/rewind gestures.

import SparkCore
import SwiftUI

struct DiscoverCardStackView: View {
    let currentCard: DiscoverCard
    let nextCard: DiscoverCard?
    let intent: LikesIntent
    let sparkBurstToken: Int
    var onPass: () -> Void
    var onLike: () -> Void
    var onOpenProfile: () -> Void
    var onRewind: () -> Void
    var onShowOpenerPicker: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var dragOffset: CGSize = .zero
    @State private var didTriggerOpenerPicker = false

    private let swipeThreshold: CGFloat = 120
    private let openerThreshold: CGFloat = 0.6

    var body: some View {
        ZStack {
            if let nextCard {
                DiscoverCardView(
                    card: nextCard,
                    isActive: false,
                    intent: intent,
                    onOpenProfile: {}
                )
                .scaleEffect(0.95 + min(0.05, abs(dragOffset.width) / 800))
                .opacity(0.9)
            }

            DiscoverCardView(
                card: currentCard,
                isActive: true,
                intent: intent,
                onOpenProfile: onOpenProfile
            )
            .offset(dragOffset)
            .rotationEffect(.degrees(Double(dragOffset.width / 20)))
            .overlay { swipeOverlay }
            .gesture(dragGesture)

            SparkBurstEmitterView(trigger: sparkBurstToken)
                .allowsHitTesting(false)
        }
        .animation(
            reduceMotion ? nil : .interactiveSpring(response: 0.3, dampingFraction: 0.7),
            value: dragOffset
        )
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                let width = value.translation.width
                let cardWidth = max(1, value.startLocation.x * 2)
                if width > cardWidth * openerThreshold, !didTriggerOpenerPicker {
                    didTriggerOpenerPicker = true
                    onShowOpenerPicker()
                }
            }
            .onEnded { value in
                defer {
                    didTriggerOpenerPicker = false
                    if reduceMotion {
                        dragOffset = .zero
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            dragOffset = .zero
                        }
                    }
                }
                let tx = value.translation.width
                let ty = value.translation.height
                if abs(tx) > abs(ty) {
                    if tx > swipeThreshold {
                        onLike()
                    } else if tx < -swipeThreshold {
                        onPass()
                    }
                    return
                }
                if ty < -swipeThreshold {
                    onOpenProfile()
                } else if ty > swipeThreshold {
                    onRewind()
                }
            }
    }

    @ViewBuilder
    private var swipeOverlay: some View {
        if dragOffset.width > 40 {
            swipeBadge(
                symbol: "heart.fill",
                color: .green,
                alignment: .topLeading
            )
        } else if dragOffset.width < -40 {
            swipeBadge(
                symbol: "xmark",
                color: .red,
                alignment: .topTrailing
            )
        }
    }

    private func swipeBadge(
        symbol: String,
        color: Color,
        alignment: Alignment
    ) -> some View {
        Image(systemName: symbol)
            .font(.largeTitle.weight(.bold))
            .foregroundStyle(color)
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .accessibilityHidden(true)
    }
}

#Preview {
    DiscoverCardStackView(
        currentCard: DiscoverCard(
            userID: UserID("preview"),
            displayName: "Preview",
            bio: "Bio",
            gender: .female,
            media: DiscoverMedia(kind: .image, url: MockURL.require("https://example.com/a.jpg")),
            interestTags: ["咖啡"]
        ),
        nextCard: nil,
        intent: .match,
        sparkBurstToken: 0,
        onPass: {},
        onLike: {},
        onOpenProfile: {},
        onRewind: {},
        onShowOpenerPicker: {}
    )
    .environment(\.discoverMediaImageCache, DiscoverMediaImageCache.previewInstance())
}
