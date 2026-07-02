// Module: SparkActivity — Share + favorite menu items (detail toolbar).

import SwiftUI

/// Share + favorite menu items for embedding in larger menus (detail toolbar).
struct ActivityShareFavoriteMenuItems: View {
    let activityID: String
    let title: String
    let shareMessage: String

    @Environment(ActivityFavoriteStore.self) private var favoriteStore

    private var isFavorite: Bool {
        favoriteStore.isFavorite(activityID: activityID)
    }

    var body: some View {
        ShareLink(
            item: ActivityInviteURL.shareLink(activityID: activityID),
            subject: Text(title),
            message: Text(shareMessage)
        ) {
            Label(
                String(localized: "activity.share.menu", defaultValue: "分享邀请", comment: "Share"),
                systemImage: "square.and.arrow.up"
            )
        }

        Button {
            favoriteStore.toggle(activityID: activityID)
        } label: {
            Label(
                favoriteMenuTitle,
                systemImage: isFavorite ? "heart.fill" : "heart"
            )
        }
    }

    private var favoriteMenuTitle: String {
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
    }
}
