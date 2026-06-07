// Module: SparkCommunity — Joined communities horizontal carousel.

import SparkDesignSystem
import SwiftUI

struct MyCommunitiesCarousel: View {
    let communities: [CommunitySummary]
    let onSelect: (CommunitySummary) -> Void
    let onExploreMore: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(communities) { community in
                    Button {
                        onSelect(community)
                    } label: {
                        CommunityPill(community: community)
                    }
                    .buttonStyle(.sparkPressable)
                }
                ExplorePill(action: onExploreMore)
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct CommunityPill: View {
    let community: CommunitySummary

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                avatar
                    .overlay {
                        if community.hasNewPosts {
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 2)
                        }
                    }
                if community.hasNewPosts {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                        .offset(x: 2, y: -2)
                }
            }
            Text(community.name)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 60)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(community.name)
    }

    @ViewBuilder
    private var avatar: some View {
        if let coverURL = community.coverURL {
            SparkCachedRemoteImage(
                url: coverURL,
                content: { image in
                    image.resizable().scaledToFill().accessibilityHidden(true)
                },
                placeholder: {
                    Color(.tertiarySystemFill)
                }
            )
            .frame(width: 56, height: 56)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.tertiarySystemFill))
                .frame(width: 56, height: 56)
        }
    }
}

private struct ExplorePill: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
        VStack(spacing: 6) {
            Circle()
                .frame(width: 56, height: 56)
                .sparkGlassSurface(Circle())
                .overlay {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            Text(String(localized: "community.explore", defaultValue: "探索更多", comment: "Explore more"))
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 60)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "community.explore", defaultValue: "探索更多", comment: "Explore more"))
        }
        .buttonStyle(.sparkPressable)
    }
}

#Preview {
    MyCommunitiesCarousel(
        communities: [
            CommunitySummary(
                id: "cm_1",
                name: "徒步爱好者",
                memberCount: 128,
                activityCount: 12,
                bio: "周末爬山"
            )
        ],
        onSelect: { _ in },
        onExploreMore: {}
    )
}
