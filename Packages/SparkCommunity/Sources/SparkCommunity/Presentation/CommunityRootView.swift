// Module: SparkCommunity — Community tab root presentation.

import SparkDesignSystem
import SwiftUI

public struct CommunityRootView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Binding private var pendingCommunityPostID: String?
    @Binding private var pendingRecapActivityID: String?
    @State var viewModel: CommunityViewModel
    @State var navigationPath = NavigationPath()
    @State var splitDestination: CommunitySplitDestination?
    @State private var recapDraft: RecapSheetItem?
    @State var profilePreview: CommunityProfilePreview?

    let repository: any CommunityPostsRepository
    private let fetchActivityRecap: ((String) async -> (title: String, scheduleLine: String)?)?
    let onOpenSearch: () -> Void
    let onOpenLikesDiscover: () -> Void
    let onLikePerson: (String) -> Void
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
        .sheet(item: $recapDraft) { draft in
            CommunityRecapDraftSheet(
                activityID: draft.activityID,
                activityTitle: draft.title,
                scheduleLine: draft.scheduleLine,
                onPublish: { try await viewModel.publishRecap($0) },
                onDismiss: { recapDraft = nil }
            )
        }
    }

    private var communityFeedShell: some View {
        SparkScreenContainer(
            navigationTitle: String(localized: "screen.community", defaultValue: "社区", comment: "Community screen"),
            embedding: .none
        ) {
            VStack(spacing: 0) {
                CommunityFeedFilterBar(selectedFilter: feedFilterBinding)
                feedContent
            }
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
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(
                    String(localized: "community.search.a11y", defaultValue: "搜索", comment: "Search")
                )
            }
        }
    }

    private var feedFilterBinding: Binding<CommunityFeedFilter> {
        Binding(
            get: { viewModel.selectedFilter },
            set: { newValue in
                Task { await viewModel.applyFilter(newValue) }
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
            loadedFeedContent
        }
    }

    var allCommunitiesSectionID: String { "community-all-section" }

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
    func feedRow(_ item: CommunityFeedItem) -> some View {
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
            recapDraft = RecapSheetItem(
                activityID: activityID,
                title: recap.title,
                scheduleLine: recap.scheduleLine
            )
        }
    }
}

private struct RecapSheetItem: Identifiable {
    let activityID: String
    let title: String
    let scheduleLine: String

    var id: String { activityID }
}

#Preview {
    CommunityRootView(repository: MockCommunityPostsRepository())
}

#Preview("Community — dark") {
    SparkPreviewSupport.darkMode {
        CommunityRootView(repository: MockCommunityPostsRepository())
    }
}

#Preview("Community — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        CommunityRootView(repository: MockCommunityPostsRepository())
    }
}

#Preview("Community — iPad split") {
    SparkPreviewSupport.iPadRegular {
        CommunityRootView(repository: MockCommunityPostsRepository())
    }
}
