// Module: SparkCommunity — Segmented home: feed vs my communities.

import SparkDesignSystem
import SwiftUI

extension CommunityRootView {
    private var discoverableSectionTitle: String {
        String(
            localized: "community.feed.section.discover",
            defaultValue: "探索社区",
            comment: "Discover communities section"
        )
    }

    private var discoverableSectionID: String { "community-discover-section" }

    /// Phone-style filter control centered in the navigation bar (Recents「所有 / 未接来电」).
    var homeSegmentToolbarPicker: some View {
        SparkToolbarSegmentedPicker(
            options: Array(CommunityHomeSegment.allCases),
            selection: $selectedSegment,
            title: \.localizedTitle,
            accessibilityLabel: String(
                localized: "community.home.segment.a11y",
                defaultValue: "社区内容分类",
                comment: "Community home segment picker"
            )
        )
    }

    @ViewBuilder
    var loadedFeedContent: some View {
        // REASONING: Single List per segment — TabView paging blocks scroll-edge transparent navigation bar.
        homeSegmentInstantContent
    }

    @ViewBuilder
    private var homeSegmentInstantContent: some View {
        SparkPreservedSegmentStack(
            selection: selectedSegment,
            segments: Array(CommunityHomeSegment.allCases)
        ) { segment in
            switch segment {
            case .feed:
                feedSegmentContent
            case .groups:
                groupsSegmentContent
            }
        }
    }

    @ViewBuilder
    private var feedSegmentContent: some View {
        compactFeedSegmentScroll
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var groupsSegmentContent: some View {
        compactGroupsSegmentScroll
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Feed segment

    private var compactFeedSegmentScroll: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if viewModel.homeFeedPosts.isEmpty {
                    feedEmptyRow
                        .padding(.top, SparkLayoutMetrics.sectionVerticalPadding)
                } else {
                    ForEach(viewModel.homeFeedPosts) { post in
                        feedPostCard(post)
                    }
                }
            }
        }
        .background(.background)
        .refreshable {
            await viewModel.load()
        }
    }

    private var feedEmptyRow: some View {
        ContentUnavailableView(
            String(localized: "community.feed.empty.title", defaultValue: "暂无相关动态", comment: "Home feed empty"),
            systemImage: "text.bubble",
            description: Text(
                String(
                    localized: "community.feed.empty.subtitle",
                    defaultValue: "局后随拍和已加入社区的帖子会显示在这里",
                    comment: "Home feed empty hint"
                )
            )
        )
        .sparkContentUnavailableCanvas()
        .sparkFlatTabListRow()
    }

    // MARK: - Groups segment

    private var compactGroupsSegmentScroll: some View {
        ScrollViewReader { proxy in
            List {
                groupsJoinedSection
                groupsDiscoverableSection
            }
            .sparkFlatTabListStyle()
            .refreshable {
                await viewModel.load()
            }
            .onChange(of: selectedSegment) { _, segment in
                guard segment == CommunityHomeSegment.groups else { return }
                scrollToPendingGroupsTarget(proxy: proxy)
            }
            .onChange(of: pendingGroupsScrollTarget) { _, _ in
                scrollToPendingGroupsTarget(proxy: proxy)
            }
        }
    }

    @ViewBuilder
    private var groupsJoinedSection: some View {
        if !viewModel.joinedCommunities.isEmpty {
            Section {
                myCommunitiesCarousel
                    .listRowInsets(
                        EdgeInsets(
                            top: SparkLayoutMetrics.communityCarouselRowTopInset,
                            leading: 0,
                            bottom: SparkLayoutMetrics.communityCarouselRowBottomInset,
                            trailing: 0
                        )
                    )
                    .listRowSeparator(.hidden)
            } header: {
                CommunityFeedSectionHeader(
                    title: String(
                        localized: "community.feed.section.myCommunities",
                        defaultValue: "我的社区",
                        comment: "My communities section"
                    )
                )
            }
        } else if !viewModel.discoverableCommunities.isEmpty {
            Section {
                CommunityJoinPromptCard(onExplore: { scrollToDiscoverableInGroups() })
                    .sparkFlatTabListRow()
            }
        }
    }

    @ViewBuilder
    private var groupsDiscoverableSection: some View {
        if !viewModel.discoverableCommunities.isEmpty {
            Section {
                ForEach(viewModel.discoverableCommunities) { community in
                    Button {
                        openCommunity(community)
                    } label: {
                        CommunityRowCell(community: community)
                    }
                    .buttonStyle(.sparkPressable)
                    .sparkFlatTabListRow()
                }
            } header: {
                CommunityFeedSectionHeader(title: discoverableSectionTitle)
                    .id(discoverableSectionID)
            }
        } else if viewModel.joinedCommunities.isEmpty {
            groupsEmptyRow
        }
    }

    private var groupsEmptyRow: some View {
        ContentUnavailableView(
            String(
                localized: "community.groups.empty.title",
                defaultValue: "暂无社区",
                comment: "Groups segment empty"
            ),
            systemImage: "person.2",
            description: Text(
                String(
                    localized: "community.groups.empty.subtitle",
                    defaultValue: "参加活动后会推荐相关社区",
                    comment: "Groups segment empty hint"
                )
            )
        )
        .sparkContentUnavailableCanvas()
        .sparkFlatTabListRow()
    }

    private var myCommunitiesCarousel: some View {
        MyCommunitiesCarousel(
            communities: viewModel.joinedCommunities,
            onSelect: { openCommunity($0) },
            onExploreMore: { scrollToDiscoverableInGroups() }
        )
        .frame(height: SparkLayoutMetrics.communityCarouselHeight)
    }

    func applyInitialHomeSegmentIfNeeded() {
        guard viewModel.loadState == .loaded, !hasAppliedInitialHomeSegment else { return }
        selectedSegment = viewModel.joinedCommunities.isEmpty
            ? CommunityHomeSegment.groups
            : CommunityHomeSegment.feed
        hasAppliedInitialHomeSegment = true
    }

    private func scrollToDiscoverableInGroups() {
        selectedSegment = CommunityHomeSegment.groups
        pendingGroupsScrollTarget = discoverableSectionID
    }

    private func scrollToPendingGroupsTarget(proxy: ScrollViewProxy) {
        guard selectedSegment == CommunityHomeSegment.groups, let target = pendingGroupsScrollTarget else { return }
        withAnimation {
            proxy.scrollTo(target, anchor: .top)
        }
        pendingGroupsScrollTarget = nil
    }

    private func feedPostCard(_ post: CommunityFeedPost) -> some View {
        CommunityPostCard(
            post: post,
            isLiked: viewModel.isPostLiked(post.id),
            likeCount: viewModel.likeCount(for: post.id),
            isLikePending: viewModel.isLikePending(post.id),
            onToggleLike: { Task { await viewModel.toggleLike(postID: post.id) } },
            onOpen: { openFeedPost(post) },
            onOpenAuthor: {
                profilePreview = CommunityProfilePreview(feedPost: post)
            },
            onOpenLinkedActivity: onOpenLinkedActivity
        )
    }
}
