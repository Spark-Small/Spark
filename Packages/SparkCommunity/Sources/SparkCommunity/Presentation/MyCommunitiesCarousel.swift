// Module: SparkCommunity — Joined communities horizontal carousel.

import SparkDesignSystem
import SwiftUI

struct MyCommunitiesCarousel: View {
    let communities: [CommunitySummary]
    let onSelect: (CommunitySummary) -> Void
    let onExploreMore: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SparkLayoutMetrics.sectionVerticalPadding) {
                ForEach(communities) { community in
                    Button {
                        onSelect(community)
                    } label: {
                        CommunityPill(community: community)
                    }
                    .buttonStyle(.sparkPressable)
                }
                Button(action: onExploreMore) {
                    ExplorePill()
                }
                .buttonStyle(.sparkPressable)
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        }
    }
}

// MARK: - Carousel avatar (joined + explore share one size)

private struct CommunityCarouselAvatar: View {
    enum Kind {
        case community(CommunitySummary)
        case exploreMore
    }

    let kind: Kind

    private var size: CGFloat { SparkLayoutMetrics.communityCarouselAvatarSize }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            circleContent
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay {
                    if case .community(let community) = kind, community.hasNewPosts {
                        Circle()
                            .stroke(Color.accentColor, lineWidth: 2)
                    }
                }
            if case .community(let community) = kind, community.hasNewPosts {
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                    .offset(x: 2, y: -2)
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var circleContent: some View {
        switch kind {
        case .community(let community):
            communityCover(url: community.coverURL)
        case .exploreMore:
            Color(.tertiarySystemFill)
                .overlay {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
        }
    }

    @ViewBuilder
    private func communityCover(url: URL?) -> some View {
        if let url {
            SparkCachedRemoteImage(
                url: url,
                maxPixelSize: 192,
                content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .accessibilityHidden(true)
                },
                placeholder: {
                    communityPlaceholder
                }
            )
        } else {
            communityPlaceholder
        }
    }

    private var communityPlaceholder: some View {
        Color(.tertiarySystemFill)
            .overlay {
                Image(systemName: "person.2.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
    }
}

private struct CommunityPill: View {
    let community: CommunitySummary

    var body: some View {
        VStack(spacing: 6) {
            CommunityCarouselAvatar(kind: .community(community))
            VStack(spacing: 2) {
                Text(community.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                if community.memberCount > 0 {
                    Text(memberLabel(community.memberCount))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: SparkLayoutMetrics.communityCarouselLabelWidth)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(community.name)
    }

    private func memberLabel(_ count: Int) -> String {
        String(
            format: String(
                localized: "community.carousel.members.short",
                defaultValue: "%d 人",
                comment: "Carousel member count; %d count"
            ),
            locale: .current,
            count
        )
    }
}

private struct ExplorePill: View {
    var body: some View {
        VStack(spacing: 6) {
            CommunityCarouselAvatar(kind: .exploreMore)
            Text(String(localized: "community.explore", defaultValue: "探索更多", comment: "Explore more"))
                .font(.caption.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: SparkLayoutMetrics.communityCarouselLabelWidth)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(localized: "community.explore", defaultValue: "探索更多", comment: "Explore more")
        )
    }
}

#Preview {
    CommunityPreviewTraits.matrix("My communities carousel") {
        MyCommunitiesCarousel(
            communities: [
                CommunitySummary(
                    id: "cm_1",
                    name: String(localized: "community.mock.hike", defaultValue: "爬山队", comment: "Community"),
                    coverURL: URL(string: "https://picsum.photos/seed/cm-hike/128/128"),
                    memberCount: 128,
                    activityCount: 12,
                    bio: String(localized: "community.mock.hike.bio", defaultValue: "一起去爬山的人都不会太差", comment: "Bio")
                ),
                CommunitySummary(
                    id: "cm_2",
                    name: String(localized: "community.mock.book", defaultValue: "读书会", comment: "Community"),
                    memberCount: 42,
                    activityCount: 5,
                    bio: ""
                )
            ],
            onSelect: { _ in },
            onExploreMore: {}
        )
    }
}
