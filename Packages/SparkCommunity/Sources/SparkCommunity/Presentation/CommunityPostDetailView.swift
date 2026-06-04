// Module: SparkCommunity — Community post detail presentation.

import SparkDesignSystem
import SwiftUI

public struct CommunityPostDetailView: View {
    @State private var viewModel: CommunityPostDetailViewModel

    public init(postID: String, repository: any CommunityPostsRepository) {
        _viewModel = State(initialValue: CommunityPostDetailViewModel(postID: postID, repository: repository))
    }

    public init(viewModel: CommunityPostDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failure(let message):
                SparkRetryUnavailableView(
                    title: String(
                        localized: "community.detail.error.title",
                        defaultValue: "无法加载帖子",
                        comment: "Post detail error"
                    ),
                    description: message
                ) {
                    Task { await viewModel.load() }
                }
            case .loaded:
                if let post = viewModel.post {
                    detailContent(post: post)
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle(viewModel.post?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.loadState == .idle {
                await viewModel.load()
            }
        }
    }

    private func detailContent(post: CommunityPostDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(post.authorDisplayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(post.body)
                    .font(.body)
                Text(replyCountLabel(for: post.replyCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(post.title), \(post.authorDisplayName)")
    }

    private func replyCountLabel(for count: Int) -> String {
        let format = String(
            localized: "community.replyCount.format",
            defaultValue: "%lld 条回复",
            comment: "Reply count; %lld is count"
        )
        return String(format: format, locale: .current, count)
    }
}

#Preview {
    NavigationStack {
        CommunityPostDetailView(postID: "cp_1", repository: MockCommunityPostsRepository())
    }
}
