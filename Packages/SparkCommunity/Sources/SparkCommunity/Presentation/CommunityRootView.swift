// Module: SparkCommunity — Community tab root presentation.

import SparkDesignSystem
import SwiftUI

public struct CommunityRootView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Binding private var pendingCommunityPostID: String?
    @Binding private var pendingRecapActivityID: String?
    @State var viewModel: CommunityViewModel
    @State var navigationPath = NavigationPath()
    @State var splitDestination: CommunitySplitDestination?
    @State private var recapDraft: (title: String, scheduleLine: String)?
    @State private var profilePreview: CommunityProfilePreview?

    let repository: any CommunityPostsRepository
    private let fetchActivityRecap: ((String) async -> (title: String, scheduleLine: String)?)?
    private let onOpenSearch: () -> Void
    private let onOpenLikesDiscover: () -> Void
    private let onLikePerson: (String) -> Void
    let onOpenLinkedActivity: (String) -> Void

    public init(
        repository: any CommunityPostsRepository,
        pendingCommunityPostID: Binding<String?> = .constant(nil),
        pendingRecapActivityID: Binding<String?> = .constant(nil),
        fetchActivityRecap: ((String) async -> (title: String, scheduleLine: String)?)? = nil,
        onOpenSearch: @escaping () -> Void = {},
        onOpenLikesDiscover: @escaping () -> Void = {},
        onLikePerson: @escaping (String) -> Void = { _ in },
        onOpenLinkedActivity: @escaping (String) -> Void = { _ in }
    ) {
        self.repository = repository
        _pendingCommunityPostID = pendingCommunityPostID
        _pendingRecapActivityID = pendingRecapActivityID
        _viewModel = State(initialValue: CommunityViewModel(repository: repository))
        self.fetchActivityRecap = fetchActivityRecap
        self.onOpenSearch = onOpenSearch
        self.onOpenLikesDiscover = onOpenLikesDiscover
        self.onLikePerson = onLikePerson
        self.onOpenLinkedActivity = onOpenLinkedActivity
    }

    public init(
        viewModel: CommunityViewModel,
        repository: any CommunityPostsRepository,
        pendingCommunityPostID: Binding<String?> = .constant(nil),
        pendingRecapActivityID: Binding<String?> = .constant(nil),
        fetchActivityRecap: ((String) async -> (title: String, scheduleLine: String)?)? = nil,
        onOpenSearch: @escaping () -> Void = {},
        onOpenLikesDiscover: @escaping () -> Void = {},
        onLikePerson: @escaping (String) -> Void = { _ in },
        onOpenLinkedActivity: @escaping (String) -> Void = { _ in }
    ) {
        self.repository = repository
        _pendingCommunityPostID = pendingCommunityPostID
        _pendingRecapActivityID = pendingRecapActivityID
        _viewModel = State(initialValue: viewModel)
        self.fetchActivityRecap = fetchActivityRecap
        self.onOpenSearch = onOpenSearch
        self.onOpenLikesDiscover = onOpenLikesDiscover
        self.onLikePerson = onLikePerson
        self.onOpenLinkedActivity = onOpenLinkedActivity
    }

    public var body: some View {
        Group {
            if usesSplitLayout {
                NavigationSplitView {
                    communityFeedShell
                } detail: {
                    splitDetail
                }
            } else {
                NavigationStack(path: $navigationPath) {
                    communityFeedShell
                        .navigationDestination(for: CommunityFeedPost.self) { post in
                            postDetailView(postID: post.id)
                        }
                        .navigationDestination(for: CommunityPost.self) { post in
                            postDetailView(postID: post.id)
                        }
                        .navigationDestination(for: String.self) { postID in
                            postDetailView(postID: postID)
                        }
                        .navigationDestination(for: CommunitySummary.self) { community in
                            CommunityDetailView(
                                communityID: community.id,
                                repository: repository,
                                likedPersonIDs: viewModel.likedPersonIDs,
                                onOpenActivity: onOpenLinkedActivity,
                                onOpenPost: { openFeedPost($0) },
                                onLikePerson: likePerson
                            )
                        }
                }
            }
        }
        .communityProfileSheet(
            preview: $profilePreview,
            likedPersonIDs: viewModel.likedPersonIDs,
            onLike: likePerson
        )
        .onChange(of: pendingCommunityPostID) { _, postID in
            guard let postID else { return }
            Task { await openPendingPost(postID: postID) }
        }
        .onChange(of: pendingRecapActivityID) { _, activityID in
            guard let activityID else { return }
            Task { await openPendingRecap(activityID: activityID) }
        }
        .onAppear {
            if let postID = pendingCommunityPostID {
                Task { await openPendingPost(postID: postID) }
            }
            if let activityID = pendingRecapActivityID {
                Task { await openPendingRecap(activityID: activityID) }
            }
        }
        .sheet(item: recapSheetBinding) { draft in
            CommunityRecapDraftSheet(
                activityTitle: draft.title,
                scheduleLine: draft.scheduleLine,
                onDismiss: { recapDraft = nil }
            )
        }
    }

    private var communityFeedShell: some View {
        SparkScreenContainer(
            navigationTitle: String(localized: "screen.community", defaultValue: "社区", comment: "Community screen"),
            embedding: .none
        ) {
            feedContent
                .task {
                    if viewModel.loadState == .idle {
                        await viewModel.load()
                    }
                }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onOpenSearch) {
                    Image(systemName: "magnifyingglass")
                }
                .accessibilityLabel(
                    String(localized: "community.search.a11y", defaultValue: "搜索", comment: "Search")
                )
            }
        }
    }

    private var recapSheetBinding: Binding<RecapSheetItem?> {
        Binding(
            get: {
                recapDraft.map { RecapSheetItem(title: $0.title, scheduleLine: $0.scheduleLine) }
            },
            set: { newValue in
                if newValue == nil { recapDraft = nil }
            }
        )
    }

    @ViewBuilder
    private var feedContent: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            ContentUnavailableView(
                String(localized: "community.empty.title", defaultValue: "暂无讨论", comment: "Empty community"),
                systemImage: "person.2",
                description: Text(
                    String(
                        localized: "community.empty.subtitle",
                        defaultValue: "发现附近的活动社区",
                        comment: "Empty community hint"
                    )
                )
            )
        case .failure(let message):
            SparkRetryUnavailableView(
                title: String(localized: "community.error.title", defaultValue: "无法加载", comment: "Community error"),
                description: message
            ) {
                Task { await viewModel.load() }
            }
        case .loaded:
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
                                    .buttonStyle(.plain)
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
    }

    private var allCommunitiesSectionID: String { "community-all-section" }

    func postDetailView(postID: String) -> some View {
        CommunityPostDetailView(
            postID: postID,
            repository: repository,
            onOpenLinkedActivity: onOpenLinkedActivity
        )
    }

    func likePerson(_ userID: String) {
        viewModel.markPersonLiked(userID)
        onLikePerson(userID)
    }

    @ViewBuilder
    private func feedRow(_ item: CommunityFeedItem) -> some View {
        switch item {
        case .post(let post):
            CommunityPostCard(
                post: post,
                isLiked: viewModel.isPostLiked(post.id),
                likeCount: viewModel.likeCount(for: post.id),
                onToggleLike: { viewModel.toggleLike(postID: post.id) },
                onOpen: { openFeedPost(post) }
            )
        case .peopleDiscovery(let users):
            PeopleDiscoveryCard(
                users: users,
                likedUserIDs: viewModel.likedPersonIDs,
                onLike: likePerson,
                onViewProfile: { profilePreview = CommunityProfilePreview(person: $0) },
                onViewMore: onOpenLikesDiscover
            )
        }
    }

    func openPendingPost(postID: String) async {
        openPostID(postID)
        pendingCommunityPostID = nil
        if viewModel.loadState == .idle {
            await viewModel.load()
        }
    }

    private func openPendingRecap(activityID: String) async {
        pendingRecapActivityID = nil
        guard let fetchActivityRecap else { return }
        if let recap = await fetchActivityRecap(activityID) {
            recapDraft = recap
        }
    }
}

private struct RecapSheetItem: Identifiable {
    let id = UUID()
    let title: String
    let scheduleLine: String
}

#Preview {
    CommunityRootView(repository: MockCommunityPostsRepository())
}
