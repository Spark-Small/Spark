// Module: SparkActivity — Shared cover image with share / favorite overlay (list + detail).

import SparkDesignSystem
import SwiftUI

struct ActivityCoverHeroView: View {
    let activityID: String
    let title: String
    let showsOverlayActions: Bool

    @Environment(ActivityFavoriteStore.self) private var favoriteStore

    init(activityID: String, title: String, showsOverlayActions: Bool = true) {
        self.activityID = activityID
        self.title = title
        self.showsOverlayActions = showsOverlayActions
    }

    private var isFavorite: Bool {
        favoriteStore.isFavorite(activityID: activityID)
    }

    var body: some View {
        SparkCachedRemoteImage(
            url: ActivityCoverImage.url(activityID: activityID),
            maxPixelSize: 800,
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
        .clipShape(
            RoundedRectangle(
                cornerRadius: SparkLayoutMetrics.activityCardHeroCornerRadius,
                style: .continuous
            )
        )
        .overlay(alignment: .topTrailing) {
            if showsOverlayActions {
                overlayActions
            }
        }
        .accessibilityHidden(true)
    }

    private var overlayActions: some View {
        HStack(spacing: 8) {
            ShareLink(
                item: ActivityInviteURL.shareLink(activityID: activityID),
                subject: Text(title),
                message: Text(ActivityInviteURL.shareMessage(title: title))
            ) {
                heroActionIcon(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(
                String(localized: "activity.row.share.a11y", defaultValue: "分享活动", comment: "Share activity")
            )

            Button {
                favoriteStore.toggle(activityID: activityID)
            } label: {
                heroActionIcon(
                    systemName: isFavorite ? "heart.fill" : "heart",
                    tint: isFavorite ? .pink : .primary
                )
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(
                isFavorite
                    ? String(
                        localized: "activity.row.unfavorite.a11y",
                        defaultValue: "取消收藏",
                        comment: "Remove favorite"
                    )
                    : String(
                        localized: "activity.row.favorite.a11y",
                        defaultValue: "收藏活动",
                        comment: "Favorite activity"
                    )
            )
        }
        .padding(SparkLayoutMetrics.activityCardHeroActionPadding)
    }

    private func heroActionIcon(systemName: String, tint: Color = .primary) -> some View {
        Image(systemName: systemName)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(
                width: SparkLayoutMetrics.activityCardHeroActionSize,
                height: SparkLayoutMetrics.activityCardHeroActionSize
            )
            .background(.ultraThinMaterial, in: Circle())
    }

    private var heroPlaceholder: some View {
        RoundedRectangle(
            cornerRadius: SparkLayoutMetrics.activityCardHeroCornerRadius,
            style: .continuous
        )
        .fill(.quaternary)
        .overlay {
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.tertiary)
        }
    }
}
