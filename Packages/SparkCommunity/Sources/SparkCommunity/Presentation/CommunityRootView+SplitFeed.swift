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
        Picker("", selection: $selectedSegment) {
            ForEach(CommunityHomeSegment.allCases) { segment in
                Text(segment.localizedTitle).tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: SparkLayoutMetrics.segmentedControlMaxWidth)
        .accessibilityLabel(
            String(
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
        switch selectedSegment {
        case .feed:
            feedSegmentContent
        case .discover:
            discoverPeopleSegmentContent
        case .groups:
            groupsSegmentContent
        }
    }

    @ViewBuilder
    private var feedSegmentContent: some View {
        Group {
            if usesSplitLayout {
                splitFeedSegmentList
            } else {
                compactFeedSegmentScroll
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var groupsSegmentContent: some View {
        Group {
            if usesSplitLayout {
                splitGroupsSegmentList
            } else {
                compactGroupsSegmentScroll
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Feed segment

    private var splitFeedSegmentList: some View {
        List(selection: $splitDestination) {
            if viewModel.homeFeedPosts.isEmpty {
                feedEmptyRow
            } else {
                ForEach(viewModel.homeFeedPosts) { post in
                    feedPostCard(post)
                        .fixedSize(horizontal: false, vertical: true)
                        .tag(CommunitySplitDestination.post(post.id))
                        .sparkFlatTabListRow()
                }
            }
        }
        .sparkFlatTabListStyle()
        .refreshable {
            await viewModel.load()
        }
    }

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

    // MARK: - Discover people segment

    @ViewBuilder
    private var discoverPeopleSegmentContent: some View {
        Group {
            if usesSplitLayout {
                discoverPeopleSegmentList
            } else {
                discoverPeopleSegmentScroll
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var discoverPeopleSegmentList: some View {
        List {
            if viewModel.discoverPeople.isEmpty {
                discoverPeopleEmptyRow
            } else {
                ForEach(viewModel.discoverPeople) { person in
                    discoverPersonRow(person)
                        .sparkFlatTabListRow()
                }
            }
        }
        .sparkFlatTabListStyle()
        .refreshable {
            await viewModel.load()
        }
    }

    private var discoverPeopleSegmentScroll: some View {
        List {
            if viewModel.discoverPeople.isEmpty {
                discoverPeopleEmptyRow
            } else {
                ForEach(viewModel.discoverPeople) { person in
                    discoverPersonRow(person)
                        .sparkFlatTabListRow()
                }
            }
        }
        .sparkFlatTabListStyle()
        .refreshable {
            await viewModel.load()
        }
    }

    private var discoverPeopleEmptyRow: some View {
        ContentUnavailableView(
            String(
                localized: "community.discoverPeople.empty.title",
                defaultValue: "暂无推荐",
                comment: "People discovery empty"
            ),
            systemImage: "person.2",
            description: Text(
                String(
                    localized: "community.discoverPeople.empty.subtitle",
                    defaultValue: "参加更多活动后，会在这里看到同局认识的人",
                    comment: "People discovery empty hint"
                )
            )
        )
        .sparkContentUnavailableCanvas()
        .sparkFlatTabListRow()
    }

    private func discoverPersonRow(_ person: DiscoveredPerson) -> some View {
        Button {
            openDiscoveredPerson(person)
        } label: {
            HStack(spacing: 12) {
                Text(String(person.displayName.prefix(1)))
                    .font(.body.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .background(.quaternary, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(person.sharedTag)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        }
        .buttonStyle(.sparkPressable)
        .accessibilityHint(
            String(
                localized: "community.discoverPeople.row.hint",
                defaultValue: "查看资料",
                comment: "Open discovered person profile"
            )
        )
    }

    func openDiscoveredPerson(_ person: DiscoveredPerson) {
        if let onOpenUserProfile {
            onOpenUserProfile(person.id)
        } else {
            profilePreview = CommunityProfilePreview(person: person)
        }
    }

    // MARK: - Groups segment

    private var splitGroupsSegmentList: some View {
        List(selection: $splitDestination) {
            groupsJoinedSection
            groupsDiscoverableSection
        }
        .sparkFlatTabListStyle()
        .refreshable {
            await viewModel.load()
        }
    }

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
                    .tag(CommunitySplitDestination.community(community.id))
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
            onToggleLike: { viewModel.toggleLike(postID: post.id) },
            onOpen: { openFeedPost(post) },
            onOpenAuthor: {
                profilePreview = CommunityProfilePreview(feedPost: post)
            }
        )
    }
}
