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
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    postHeader(post: post)
                    if !post.replies.isEmpty {
                        repliesSection(replies: post.replies)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            replyComposer
        }
        .accessibilityElement(children: .contain)
    }

    private func postHeader(post: CommunityPostDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.authorDisplayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(post.body)
                .font(.body)
            Text(replyCountLabel(for: post.replyCount))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(post.title), \(post.authorDisplayName)")
    }

    private func repliesSection(replies: [CommunityPostReply]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                String(
                    localized: "community.replies.section.title",
                    defaultValue: "回复",
                    comment: "Replies section"
                )
            )
            .font(.headline)
            ForEach(replies) { reply in
                VStack(alignment: .leading, spacing: 4) {
                    Text(reply.authorDisplayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(reply.body)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(reply.authorDisplayName), \(reply.body)")
            }
        }
    }

    private var replyComposer: some View {
        VStack(spacing: 8) {
            if case .failure(let message) = viewModel.replyState {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(alignment: .bottom, spacing: 8) {
                TextField(
                    String(
                        localized: "community.reply.placeholder",
                        defaultValue: "写回复…",
                        comment: "Reply placeholder"
                    ),
                    text: $viewModel.replyDraft,
                    axis: .vertical
                )
                .lineLimit(1 ... 4)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(
                    String(
                        localized: "community.reply.field.a11y",
                        defaultValue: "回复内容",
                        comment: "Reply field"
                    )
                )
                Button {
                    Task { await viewModel.sendReply() }
                } label: {
                    if viewModel.replyState == .sending {
                        ProgressView()
                    } else {
                        Text(
                            String(
                                localized: "community.reply.send",
                                defaultValue: "发送",
                                comment: "Send reply"
                            )
                        )
                    }
                }
                .disabled(
                    viewModel.replyState == .sending ||
                        viewModel.replyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
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
