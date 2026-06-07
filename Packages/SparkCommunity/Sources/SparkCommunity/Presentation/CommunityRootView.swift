// Module: SparkCommunity — Community tab root presentation.

import SparkCore
import SparkDesignSystem
import SparkPayments
import SwiftUI

enum CommunityHomeSegment: String, CaseIterable, Identifiable, Sendable {
    case feed
    case groups

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .feed:
            String(
                localized: "community.home.segment.feed",
                defaultValue: "动态",
                comment: "Community home feed segment"
            )
        case .groups:
            String(
                localized: "community.home.segment.groups",
                defaultValue: "我的社区",
                comment: "Community home groups segment"
            )
        }
    }
}

public struct CommunityRootView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Binding private var pendingCommunityPostID: String?
    @Binding private var pendingRecapActivityID: String?
    @State var viewModel: CommunityViewModel
    @State var navigationPath = NavigationPath()
    @State var splitDestination: CommunitySplitDestination?
    @State private var activityShareDraft: ActivityShareSheetItem?
    @State var profilePreview: CommunityProfilePreview?
    @State private var showComposePost = false
    @State private var composeViewModel: CreateCommunityPostViewModel?
    @State var selectedSegment: CommunityHomeSegment = CommunityHomeSegment.feed
    @State var hasAppliedInitialHomeSegment = false
    @State var pendingGroupsScrollTarget: String?

    let coordinator: CommunityCoordinator
    private let fetchActivityShareContext: ((String) async -> ActivityShareContext?)?
    let onLikePerson: (String) -> Void
    let onOpenLinkedActivity: (String) -> Void

    public init(
        coordinator: CommunityCoordinator,
        pendingCommunityPostID: Binding<String?> = .constant(nil),
        pendingRecapActivityID: Binding<String?> = .constant(nil),
        fetchActivityShareContext: ((String) async -> ActivityShareContext?)? = nil,
        onLikePerson: @escaping (String) -> Void = { _ in },
        onOpenLinkedActivity: @escaping (String) -> Void = { _ in }
    ) {
        self.coordinator = coordinator
        _pendingCommunityPostID = pendingCommunityPostID
        _pendingRecapActivityID = pendingRecapActivityID
        _viewModel = State(initialValue: coordinator.makeTabViewModel())
        self.fetchActivityShareContext = fetchActivityShareContext
        self.onLikePerson = onLikePerson
        self.onOpenLinkedActivity = onOpenLinkedActivity
    }

    public init(
        viewModel: CommunityViewModel,
        coordinator: CommunityCoordinator,
        pendingCommunityPostID: Binding<String?> = .constant(nil),
        pendingRecapActivityID: Binding<String?> = .constant(nil),
        fetchActivityShareContext: ((String) async -> ActivityShareContext?)? = nil,
        onLikePerson: @escaping (String) -> Void = { _ in },
        onOpenLinkedActivity: @escaping (String) -> Void = { _ in }
    ) {
        self.coordinator = coordinator
        _pendingCommunityPostID = pendingCommunityPostID
        _pendingRecapActivityID = pendingRecapActivityID
        _viewModel = State(initialValue: viewModel)
        self.fetchActivityShareContext = fetchActivityShareContext
        self.onLikePerson = onLikePerson
        self.onOpenLinkedActivity = onOpenLinkedActivity
    }

    public var body: some View {
        Group {
            if usesSplitLayout {
                NavigationSplitView {
                    communityFeedShell
                        .navigationSplitViewColumnWidth(
                            min: 280,
                            ideal: SparkLayoutMetrics.navigationSplitSidebarIdealWidth,
                            max: 400
                        )
                } detail: {
                    splitDetail
                }
                .navigationSplitViewStyle(.balanced)
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
                                viewModel: coordinator.makeDetailViewModel(communityID: community.id),
                                likedPersonIDs: viewModel.likedPersonIDs,
                                onOpenActivity: onOpenLinkedActivity,
                                onOpenPost: { openFeedPost($0) },
                                onLikePerson: likePerson,
                                onCommunityJoined: { Task { await viewModel.load() } }
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
            Task { await openPendingActivityShare(activityID: activityID) }
        }
        .onAppear {
            if let postID = pendingCommunityPostID {
                Task { await openPendingPost(postID: postID) }
            }
            if let activityID = pendingRecapActivityID {
                Task { await openPendingActivityShare(activityID: activityID) }
            }
        }
        .sheet(item: $activityShareDraft) { draft in
            CommunityRecapDraftSheet(
                context: draft.context,
                onPublish: { draft in
                    let detail = try await viewModel.publishRecap(draft)
                    selectedSegment = CommunityHomeSegment.feed
                    return detail
                },
                onDismiss: { activityShareDraft = nil }
            )
        }
    }

    private var communityFeedShell: some View {
        SparkScreenContainer(
            navigationTitle: "",
            titleDisplayMode: .inline,
            embedding: .none
        ) {
            feedContent
                .task {
                    if viewModel.loadState == .idle {
                        await viewModel.load()
                    }
                }
        }
        .sheet(isPresented: $showComposePost) {
            NavigationStack {
                if let composeViewModel {
                    CreateCommunityPostView(
                        viewModel: composeViewModel,
                        onCancel: { showComposePost = false },
                        onPublished: { result in
                            viewModel.insertPublishedPost(result)
                            showComposePost = false
                        }
                    )
                } else {
                    ProgressView().sparkLoadingAccessibilityLabel()
                }
            }
            .presentationDetents([.medium, .large])
        }
        .onChange(of: showComposePost) { _, isPresented in
            if isPresented, composeViewModel == nil {
                composeViewModel = coordinator.makeCreatePostViewModel()
            }
        }
        .onChange(of: viewModel.loadState) { _, _ in
            applyInitialHomeSegmentIfNeeded()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if showsHomeSegmentPicker {
                    homeSegmentToolbarPicker
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if SparkFeatureFlags.isCommunityPostingEnabled {
                    Button {
                        showComposePost = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel(
                        String(localized: "community.compose.a11y", defaultValue: "发帖", comment: "Compose post")
                    )
                }
            }
        }
        .sparkPhoneStyleNavigationBar()
    }

    private var showsHomeSegmentPicker: Bool {
        switch viewModel.loadState {
        case .failure:
            false
        case .idle, .loading, .empty, .loaded:
            true
        }
    }

    @ViewBuilder
    private var feedContent: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sparkLoadingAccessibilityLabel(
                    String(
                        localized: "community.feed.loading.a11y",
                        defaultValue: "正在加载社区",
                        comment: "Community feed loading"
                    )
                )
        case .empty:
            loadedFeedContent
                .onAppear {
                    selectedSegment = CommunityHomeSegment.groups
                }
        case .failure(let message):
            SparkRetryUnavailableView(
                title: String(localized: "community.error.title", defaultValue: "无法加载", comment: "Community error"),
                description: message
            ) {
                Task { await viewModel.load() }
            }
        case .loaded:
            loadedFeedContent
                .onAppear {
                    applyInitialHomeSegmentIfNeeded()
                }
        }
    }

    func postDetailView(postID: String) -> some View {
        CommunityPostDetailView(
            viewModel: coordinator.makePostDetailViewModel(postID: postID),
            onOpenLinkedActivity: onOpenLinkedActivity
        )
    }

    func likePerson(_ userID: String) {
        viewModel.markPersonLiked(userID)
        onLikePerson(userID)
    }

    func openPendingPost(postID: String) async {
        openPostID(postID)
        pendingCommunityPostID = nil
        if viewModel.loadState == .idle {
            await viewModel.load()
        }
    }

    private func openPendingActivityShare(activityID: String) async {
        pendingRecapActivityID = nil
        guard let fetchActivityShareContext else { return }
        if let context = await fetchActivityShareContext(activityID) {
            activityShareDraft = ActivityShareSheetItem(context: context)
        }
    }

}

private struct ActivityShareSheetItem: Identifiable {
    let context: ActivityShareContext

    var id: String { context.activityID }
}

#Preview {
    CommunityRootView(coordinator: CommunityCoordinator(repository: MockCommunityPostsRepository()))
}

#Preview("Community — dark") {
    SparkPreviewSupport.darkMode {
        CommunityRootView(coordinator: CommunityCoordinator(repository: MockCommunityPostsRepository()))
    }
}

#Preview("Community — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        CommunityRootView(coordinator: CommunityCoordinator(repository: MockCommunityPostsRepository()))
    }
}

#Preview("Community — iPad split") {
    SparkPreviewSupport.iPadRegular {
        CommunityRootView(coordinator: CommunityCoordinator(repository: MockCommunityPostsRepository()))
    }
}
