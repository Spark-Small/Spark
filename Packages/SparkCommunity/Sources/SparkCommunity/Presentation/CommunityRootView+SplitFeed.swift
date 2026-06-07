// Module: SparkCommunity — iPad split feed with List(selection:) (HIG master-detail).

import SparkDesignSystem
import SwiftUI

extension CommunityRootView {
    @ViewBuilder
    var loadedFeedContent: some View {
        if viewModel.selectedFilter == .recaps {
            recapPostsContent
        } else if usesSplitLayout {
            splitFeedList
        } else {
            compactFeedScroll
        }
    }

    @ViewBuilder
    var recapPostsContent: some View {
        if viewModel.filteredPosts.isEmpty {
            ContentUnavailableView(
                String(
                    localized: "community.recap.empty.title",
                    defaultValue: "暂无活动复盘",
                    comment: "Empty recap filter"
                ),
                systemImage: "calendar.badge.clock",
                description: Text(
                    String(
                        localized: "community.recap.empty.subtitle",
                        defaultValue: "活动结束后可以在这里分享感受",
                        comment: "Empty recap hint"
                    )
                )
            )
        } else if usesSplitLayout {
            List(selection: $splitDestination) {
                Section {
                    ForEach(viewModel.filteredPosts) { post in
                        CommunityRecapPostRow(post: post) {
                            openPostID(post.id)
                        }
                        .tag(CommunitySplitDestination.post(post.id))
                    }
                }
            }
            .sparkScreenListStyle()
            .refreshable { await viewModel.load() }
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredPosts) { post in
                        CommunityRecapPostRow(post: post) {
                            openPostID(post.id)
                        }
                        Divider()
                    }
                }
            }
            .refreshable { await viewModel.load() }
        }
    }

    var splitFeedList: some View {
        List(selection: $splitDestination) {
            if !viewModel.joinedCommunities.isEmpty {
                Section {
                    MyCommunitiesCarousel(
                        communities: viewModel.joinedCommunities,
                        onSelect: { openCommunity($0) },
                        onExploreMore: {
                            splitDestination = .community(viewModel.allCommunities.first?.id ?? "")
                        }
                    )
                    .frame(height: 88)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowSeparator(.hidden)
                }
            }

            Section {
                ForEach(viewModel.feedItems) { item in
                    splitFeedRow(item)
                }
            } header: {
                CommunityFeedSectionHeader(
                    title: String(
                        localized: "community.feed.section.discover",
                        defaultValue: "发现",
                        comment: "Discover section"
                    )
                )
            }

            if !viewModel.allCommunities.isEmpty {
                Section {
                    ForEach(viewModel.allCommunities) { community in
                        CommunityRowCell(community: community)
                            .tag(CommunitySplitDestination.community(community.id))
                    }
                } header: {
                    CommunityFeedSectionHeader(
                        title: String(
                            localized: "community.feed.section.allCommunities",
                            defaultValue: "所有社区",
                            comment: "All communities"
                        )
                    )
                }
            }
        }
        .sparkScreenListStyle()
        .refreshable {
            await viewModel.load()
        }
    }

    var compactFeedScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    if !viewModel.joinedCommunities.isEmpty {
                        Section {
                            MyCommunitiesCarousel(
                                communities: viewModel.joinedCommunities,
                                onSelect: { openCommunity($0) },
                                onExploreMore: {
                                    if reduceMotion {
                                        proxy.scrollTo(allCommunitiesSectionID, anchor: .top)
                                    } else {
                                        withAnimation {
                                            proxy.scrollTo(allCommunitiesSectionID, anchor: .top)
                                        }
                                    }
                                }
                            )
                            .frame(height: 88)
                            .padding(.vertical, 8)
                        }
                    }

                    Section {
                        ForEach(viewModel.feedItems) { item in
                            feedRow(item)
                        }
                    } header: {
                        CommunityFeedSectionHeader(
                            title: String(
                                localized: "community.feed.section.discover",
                                defaultValue: "发现",
                                comment: "Discover section"
                            )
                        )
                    }

                    if !viewModel.allCommunities.isEmpty {
                        Section {
                            ForEach(viewModel.allCommunities) { community in
                                Button {
                                    openCommunity(community)
                                } label: {
                                    CommunityRowCell(community: community)
                                }
                                .buttonStyle(.sparkPressable)
                                Divider()
                            }
                        } header: {
                            CommunityFeedSectionHeader(
                                title: String(
                                    localized: "community.feed.section.allCommunities",
                                    defaultValue: "所有社区",
                                    comment: "All communities"
                                )
                            )
                            .id(allCommunitiesSectionID)
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    func splitFeedRow(_ item: CommunityFeedItem) -> some View {
        switch item {
        case .post(let post):
            CommunityPostCard(
                post: post,
                isLiked: viewModel.isPostLiked(post.id),
                likeCount: viewModel.likeCount(for: post.id),
                onToggleLike: { viewModel.toggleLike(postID: post.id) },
                onOpen: { openFeedPost(post) }
            )
            .tag(CommunitySplitDestination.post(post.id))
        case .peopleDiscovery(let users):
            PeopleDiscoveryCard(
                users: users,
                likedUserIDs: viewModel.likedPersonIDs,
                onLike: likePerson,
                onViewProfile: { profilePreview = CommunityProfilePreview(person: $0) },
                onViewMore: onOpenLikesDiscover
            )
            .listRowInsets(EdgeInsets())
        }
    }
}
