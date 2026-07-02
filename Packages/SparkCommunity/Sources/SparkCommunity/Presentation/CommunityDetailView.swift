// Module: SparkCommunity — Instagram-style community detail.

import SparkDesignSystem
import SwiftUI

public struct CommunityDetailView: View {
    @State private var viewModel: CommunityDetailViewModel
    @State private var showsMembersSheet = false
    @State private var profilePreview: CommunityProfilePreview?

    private let onOpenActivity: (String) -> Void
    private let onOpenPost: (CommunityFeedPost) -> Void
    private let onLikePerson: (String) -> Void
    private let onCommunityJoined: (() -> Void)?
    private let likedPersonIDs: Set<String>

    public init(
        communityID: String,
        coordinator: CommunityCoordinator,
        likedPersonIDs: Set<String> = [],
        onOpenActivity: @escaping (String) -> Void = { _ in },
        onOpenPost: @escaping (CommunityFeedPost) -> Void = { _ in },
        onLikePerson: @escaping (String) -> Void = { _ in },
        onCommunityJoined: (() -> Void)? = nil
    ) {
        self.init(
            viewModel: coordinator.makeDetailViewModel(communityID: communityID),
            likedPersonIDs: likedPersonIDs,
            onOpenActivity: onOpenActivity,
            onOpenPost: onOpenPost,
            onLikePerson: onLikePerson,
            onCommunityJoined: onCommunityJoined
        )
    }

    public init(
        viewModel: CommunityDetailViewModel,
        likedPersonIDs: Set<String> = [],
        onOpenActivity: @escaping (String) -> Void = { _ in },
        onOpenPost: @escaping (CommunityFeedPost) -> Void = { _ in },
        onLikePerson: @escaping (String) -> Void = { _ in },
        onCommunityJoined: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.likedPersonIDs = likedPersonIDs
        self.onOpenActivity = onOpenActivity
        self.onOpenPost = onOpenPost
        self.onLikePerson = onLikePerson
        self.onCommunityJoined = onCommunityJoined
    }

    public var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sparkLoadingAccessibilityLabel(
                        String(
                            localized: "community.detail.loading.a11y",
                            defaultValue: "正在加载社区",
                            comment: "Community detail loading"
                        )
                    )
            case .failure(let message):
                SparkRetryUnavailableView(
                    title: String(
                        localized: "community.detail.error.title",
                        defaultValue: "无法加载社区",
                        comment: "Community detail error"
                    ),
                    description: message
                ) {
                    Task { await viewModel.load() }
                }
            case .loaded:
                if let detail = viewModel.detail {
                    detailContent(detail: detail)
                } else {
                    ProgressView()
                        .sparkLoadingAccessibilityLabel(
                            String(
                                localized: "community.detail.loading.a11y",
                                defaultValue: "正在加载社区",
                                comment: "Community detail loading"
                            )
                        )
                }
            }
        }
        .navigationTitle(viewModel.detail?.summary.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.loadState == .idle {
                await viewModel.load()
            }
        }
        .sheet(isPresented: $showsMembersSheet) {
            CommunityMembersSheet(members: viewModel.members) { member in
                profilePreview = CommunityProfilePreview(member: member)
            }
        }
        .communityProfileSheet(
            preview: $profilePreview,
            likedPersonIDs: likedPersonIDs,
            onLike: onLikePerson
        )
        .alert(
            String(
                localized: "community.detail.join.error.title",
                defaultValue: "无法加入社区",
                comment: "Join community error title"
            ),
            isPresented: joinFailureBinding
        ) {
            Button(String(localized: "action.ok", defaultValue: "好", comment: "OK")) {
                viewModel.dismissJoinError()
            }
        } message: {
            if case let .failure(message) = viewModel.joinState {
                Text(message)
            }
        }
        .onChange(of: viewModel.detail?.isJoined) { _, isJoined in
            if isJoined == true {
                onCommunityJoined?()
            }
        }
    }

    private var joinFailureBinding: Binding<Bool> {
        Binding(
            get: {
                if case .failure = viewModel.joinState { return true }
                return false
            },
            set: { if !$0 { viewModel.dismissJoinError() } }
        )
    }

    private func detailContent(detail: CommunityDetail) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                CommunityDetailHeaderView(
                    detail: detail,
                    members: viewModel.members,
                    isJoining: viewModel.isJoining,
                    onJoin: { Task { await viewModel.join() } },
                    onShowMembers: { showsMembersSheet = true }
                )
                segmentPicker
                segmentContent
            }
        }
    }

    private var segmentPicker: some View {
        Picker("", selection: $viewModel.selectedSegment) {
            Text(
                String(localized: "community.detail.segment.activities", defaultValue: "最近活动", comment: "Activities tab")
            )
            .tag(CommunityDetailViewModel.Segment.activities)
            Text(
                String(localized: "community.detail.segment.posts", defaultValue: "帖子", comment: "Posts tab")
            )
            .tag(CommunityDetailViewModel.Segment.posts)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 280)
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
    }

    @ViewBuilder
    private var segmentContent: some View {
        SparkPreservedSegmentStack(
            selection: viewModel.selectedSegment,
            segments: Array(CommunityDetailViewModel.Segment.allCases)
        ) { segment in
            switch segment {
            case .activities:
                activitiesTab
            case .posts:
                postsTab
            }
        }
    }

    private var activitiesTab: some View {
        LazyVStack(spacing: 0) {
            if viewModel.activities.isEmpty {
                ContentUnavailableView(
                    String(
                        localized: "community.detail.activities.empty",
                        defaultValue: "暂无活动",
                        comment: "No activities"
                    ),
                    systemImage: "calendar"
                )
                .padding(.vertical, SparkLayoutMetrics.communityDetailEmptyTabPadding)
            } else {
                ForEach(viewModel.activities) { activity in
                    CommunityLinkedActivityRow(activity: activity) {
                        onOpenActivity(activity.id)
                    }
                    Divider()
                }
            }
        }
    }

    private var postsTab: some View {
        LazyVStack(spacing: 0) {
            if viewModel.posts.isEmpty {
                ContentUnavailableView(
                    String(
                        localized: "community.detail.posts.empty",
                        defaultValue: "暂无帖子",
                        comment: "No posts"
                    ),
                    systemImage: "text.bubble"
                )
                .padding(.vertical, SparkLayoutMetrics.communityDetailEmptyTabPadding)
            } else {
                ForEach(viewModel.posts) { post in
                    Button {
                        onOpenPost(post)
                    } label: {
                        CommunityFeedPostRow(post: post)
                    }
                    .buttonStyle(.sparkPressable)
                    Divider()
                }
            }
        }
    }

}

#Preview {
    CommunityPreviewTraits.matrix("Community detail") {
        NavigationStack {
            CommunityDetailView(
                communityID: "cm_run",
                coordinator: CommunityCoordinator(repository: MockCommunityPostsRepository())
            )
        }
    }
}
