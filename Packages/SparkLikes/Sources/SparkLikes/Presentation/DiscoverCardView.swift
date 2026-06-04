// Module: SparkLikes — Single full-screen discover card.

import SparkCore
import SwiftUI

struct DiscoverCardView: View {
    let card: DiscoverCard
    let isActive: Bool
    let intent: LikesIntent
    var onOpenProfile: () -> Void

    @State private var zoomState = DiscoverPhotoZoomState()

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            DiscoverCardMediaView(card: card, isActive: isActive, zoomState: zoomState)
            cardInfoOverlay
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(cardAccessibilityLabel)
        .accessibilityHint(
            String(
                localized: "likes.card.profile.a11y",
                defaultValue: "点按查看完整资料",
                comment: "Open profile a11y"
            )
        )
    }

    private var cardInfoOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let gender = card.gender {
                Text(gender.localizedLabel)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }
            Text(card.displayName)
                .font(.title2.weight(.bold))
            if let activity = card.sharedActivityTitle {
                Label(activity, systemImage: "calendar")
                    .font(.caption.weight(.medium))
            }
            if !card.bio.isEmpty {
                Text(card.bio)
                    .font(.subheadline)
                    .lineLimit(2)
            }
            if card.galleryMedia.count > 1 || !card.interestTags.isEmpty {
                Text(
                    String(
                        localized: "likes.card.profileHint",
                        defaultValue: "上滑查看资料",
                        comment: "Profile hint"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .padding(.bottom, intent == .friends ? 120 : 88)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { cardInfoScrim }
        .contentShape(Rectangle())
        .onTapGesture {
            onOpenProfile()
        }
    }

    private var cardInfoScrim: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask(
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private var cardAccessibilityLabel: String {
        let format = String(
            localized: "likes.card.a11y.format",
            defaultValue: "%1$@, %2$@",
            comment: "Card a11y; name, bio"
        )
        return String(format: format, locale: .current, card.displayName, card.bio)
    }
}

#Preview {
    DiscoverCardView(
        card: DiscoverCard(
            userID: UserID("preview"),
            displayName: "Preview",
            bio: "Bio",
            gender: .female,
            media: DiscoverMedia(kind: .image, url: URL(string: "https://example.com/a.jpg")!),
            interestTags: ["咖啡"]
        ),
        isActive: true,
        intent: .match,
        onOpenProfile: {}
    )
}

#Preview("Discover card — dark") {
    LikesPreviewSupport.darkMode {
        DiscoverCardView(
            card: DiscoverCard(
                userID: UserID("preview"),
                displayName: "Preview",
                bio: "Bio",
                gender: .female,
                media: DiscoverMedia(kind: .image, url: URL(string: "https://example.com/a.jpg")!),
                interestTags: ["咖啡"]
            ),
            isActive: true,
            intent: .match,
            onOpenProfile: {}
        )
    }
}
