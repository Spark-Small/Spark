// Module: SparkCommunity — Community tab root presentation.

import SparkDesignSystem
import SwiftUI

public struct CommunityRootView: View {
    @Binding private var pendingCommunityPostID: String?
    @Binding private var pendingRecapActivityID: String?
    @State private var viewModel: CommunityViewModel
    @State private var navigationPath = NavigationPath()
    @State private var recapDraft: (title: String, scheduleLine: String)?

    private let repository: any CommunityPostsRepository
    private let fetchActivityRecap: ((String) async -> (title: String, scheduleLine: String)?)?

    public init(
        repository: any CommunityPostsRepository,
        pendingCommunityPostID: Binding<String?> = .constant(nil),
        pendingRecapActivityID: Binding<String?> = .constant(nil),
        fetchActivityRecap: ((String) async -> (title: String, scheduleLine: String)?)? = nil
    ) {
        self.repository = repository
        _pendingCommunityPostID = pendingCommunityPostID
        _pendingRecapActivityID = pendingRecapActivityID
        _viewModel = State(initialValue: CommunityViewModel(repository: repository))
        self.fetchActivityRecap = fetchActivityRecap
    }

    public init(
        viewModel: CommunityViewModel,
        repository: any CommunityPostsRepository,
        pendingCommunityPostID: Binding<String?> = .constant(nil),
        pendingRecapActivityID: Binding<String?> = .constant(nil),
        fetchActivityRecap: ((String) async -> (title: String, scheduleLine: String)?)? = nil
    ) {
        self.repository = repository
        _pendingCommunityPostID = pendingCommunityPostID
        _pendingRecapActivityID = pendingRecapActivityID
        _viewModel = State(initialValue: viewModel)
        self.fetchActivityRecap = fetchActivityRecap
    }

    public var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .navigationDestination(for: CommunityPost.self) { post in
                CommunityPostDetailView(postID: post.id, repository: repository)
            }
            .navigationDestination(for: String.self) { postID in
                CommunityPostDetailView(postID: postID, repository: repository)
            }
        }
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
                        defaultValue: "来发第一条帖子吧",
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
            List(viewModel.posts) { post in
                NavigationLink(value: post) {
                    CommunityPostRow(post: post)
                }
            }
            .sparkScreenListStyle()
        }
    }

    private func openPendingPost(postID: String) async {
        // REASONING: Detail loads by id; do not block on feed (search/deep link may arrive before list finishes).
        navigationPath.append(postID)
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

private struct CommunityPostRow: View {
    let post: CommunityPost

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(post.title)
                .font(.headline)
            Text(post.excerpt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 8) {
                Text(post.authorDisplayName)
                Text("·")
                Text(replyCountLabel)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(post.title), \(post.authorDisplayName)")
    }

    private var replyCountLabel: String {
        let format = String(
            localized: "community.replyCount.format",
            defaultValue: "%lld 条回复",
            comment: "Reply count; %lld is count"
        )
        return String(format: format, locale: .current, post.replyCount)
    }
}

#Preview {
    CommunityRootView(repository: MockCommunityPostsRepository())
}
