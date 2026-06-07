// Module: SparkCommunity — Meet people from shared activities.

import SparkDesignSystem
import SwiftUI

struct PeopleDiscoveryCard: View {
    let users: [DiscoveredPerson]
    let likedUserIDs: Set<String>
    let onLike: (String) -> Void
    let onViewProfile: (DiscoveredPerson) -> Void
    let onViewMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "community.feed.people.title", defaultValue: "认识新朋友", comment: "People title"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(users.prefix(6)) { user in
                        PeopleMiniCard(
                            user: user,
                            isLiked: likedUserIDs.contains(user.id),
                            onLike: { onLike(user.id) },
                            onViewProfile: { onViewProfile(user) }
                        )
                    }
                    ViewMoreCell(action: onViewMore)
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .sparkGlassSurface(RoundedRectangle.sparkCard)
    }
}

private struct PeopleMiniCard: View {
    let user: DiscoveredPerson
    let isLiked: Bool
    let onLike: () -> Void
    let onViewProfile: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onViewProfile) {
                avatar
            }
            .buttonStyle(.sparkPressable)
            .accessibilityLabel(user.displayName)
            Text(user.displayName)
                .font(.caption)
                .lineLimit(1)
            RelationshipBadge(context: user.relationship)
            Text(user.sharedTag)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Button(action: onLike) {
                Image(systemName: isLiked ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isLiked ? .green : .accentColor)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.sparkPressable)
            .disabled(isLiked)
            .accessibilityLabel(
                isLiked
                    ? String(localized: "community.people.liked.a11y", defaultValue: "已喜欢", comment: "Liked")
                    : String(localized: "community.people.like.a11y", defaultValue: "喜欢", comment: "Like person")
            )
        }
        .frame(width: 72)
    }

    @ViewBuilder
    private var avatar: some View {
        if let url = user.avatarURL {
            SparkCachedRemoteImage(
                url: url,
                content: { image in
                    image.resizable().scaledToFill().accessibilityHidden(true)
                },
                placeholder: {
                    Circle().fill(.clear)
                }
            )
            .frame(width: 48, height: 48)
            .sparkGlassControl(Circle())
            .clipShape(Circle())
        } else {
            Circle()
                .frame(width: 48, height: 48)
                .sparkGlassControl(Circle())
        }
    }
}

private struct ViewMoreCell: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .frame(width: 48, height: 48)
                    .sparkGlassControl(Circle())
                    .overlay {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                Text(String(localized: "community.people.viewMore", defaultValue: "查看更多", comment: "View more"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 72)
        }
        .buttonStyle(.sparkPressable)
        .accessibilityLabel(
            String(localized: "community.people.viewMore.a11y", defaultValue: "查看更多推荐用户", comment: "View more people")
        )
    }
}

#Preview {
    PeopleDiscoveryCard(
        users: [
            DiscoveredPerson(
                id: "u1",
                displayName: "Nova",
                sharedTag: "也去了玉林咖啡局",
                relationship: .sharedActivity("玉林咖啡局")
            )
        ],
        likedUserIDs: [],
        onLike: { _ in },
        onViewProfile: { _ in },
        onViewMore: {}
    )
    .padding()
}
