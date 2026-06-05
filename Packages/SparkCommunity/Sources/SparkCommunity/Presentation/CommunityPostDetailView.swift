// Module: SparkCommunity — Community post detail presentation.

import SparkDesignSystem
import SwiftUI

public struct CommunityPostDetailView: View {
    @State private var viewModel: CommunityPostDetailViewModel
    private let onOpenLinkedActivity: ((String) -> Void)?

    public init(
        postID: String,
        repository: any CommunityPostsRepository,
        onOpenLinkedActivity: ((String) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: CommunityPostDetailViewModel(postID: postID, repository: repository))
        self.onOpenLinkedActivity = onOpenLinkedActivity
    }

    public init(
        viewModel: CommunityPostDetailViewModel,
        onOpenLinkedActivity: ((String) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenLinkedActivity = onOpenLinkedActivity
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
            if let linkedActivity = post.linkedActivity {
                activityBanner(linkedActivity)
            }
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
            postingComingSoonBar
        }
        .accessibilityElement(children: .contain)
    }

    private func activityBanner(_ activity: LinkedActivityContext) -> some View {
        Button {
            onOpenLinkedActivity?(activity.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        String(
                            format: String(
                                localized: "community.detail.activityBanner.title",
                                defaultValue: "这条帖子来自「%@」活动群",
                                comment: "Activity banner; %@ is activity name"
                            ),
                            locale: .current,
                            activity.name
                        )
                    )
                    .font(.subheadline.weight(.medium))
                    Text(
                        String(
                            localized: "community.detail.activityBanner.action",
                            defaultValue: "查看活动详情",
                            comment: "Open activity"
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
        }
        .buttonStyle(.plain)
        .disabled(onOpenLinkedActivity == nil)
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

    private var postingComingSoonBar: some View {
        Text(
            String(
                localized: "community.posting.comingSoon",
                defaultValue: "发帖功能即将开放",
                comment: "Posting coming soon"
            )
        )
        .font(.footnote)
        .foregroundStyle(.tertiary)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.bar)
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
