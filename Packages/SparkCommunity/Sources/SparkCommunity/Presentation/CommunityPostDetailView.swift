// Module: SparkCommunity — Community post detail presentation.

import SparkDesignSystem
import SwiftUI

public struct CommunityPostDetailView: View {
    @State private var viewModel: CommunityPostDetailViewModel
    @State private var showReportSheet = false
    private let onOpenLinkedActivity: ((String) -> Void)?

    public init(
        postID: String,
        coordinator: CommunityCoordinator,
        onOpenLinkedActivity: ((String) -> Void)? = nil
    ) {
        self.init(
            viewModel: coordinator.makePostDetailViewModel(postID: postID),
            onOpenLinkedActivity: onOpenLinkedActivity
        )
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
                    .sparkLoadingAccessibilityLabel(
                        String(
                            localized: "community.post.loading.a11y",
                            defaultValue: "正在加载帖子",
                            comment: "Post detail loading"
                        )
                    )
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
                        .sparkLoadingAccessibilityLabel(
                            String(
                                localized: "community.post.loading.a11y",
                                defaultValue: "正在加载帖子",
                                comment: "Post detail loading"
                            )
                        )
                }
            }
        }
        .navigationTitle(viewModel.post?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.loadState == .loaded {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        String(localized: "community.report.title", defaultValue: "举报帖子", comment: "Report title"),
                        systemImage: "exclamationmark.bubble"
                    ) {
                        showReportSheet = true
                    }
                    .buttonStyle(.sparkPressable)
                    .accessibilityHint(
                        String(
                            localized: "community.report.toolbar.hint",
                            defaultValue: "举报不当内容",
                            comment: "Report toolbar hint"
                        )
                    )
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            CommunityReportSheet { reason, detail in
                Task { await viewModel.submitReport(reason: reason, detail: detail) }
            }
        }
        .alert(
            String(
                localized: "community.report.success.title",
                defaultValue: "举报已提交",
                comment: "Report success title"
            ),
            isPresented: reportSuccessBinding
        ) {
            Button(String(localized: "action.ok", defaultValue: "好", comment: "OK")) {
                viewModel.dismissReportFeedback()
            }
        } message: {
            Text(
                String(
                    localized: "community.report.success.message",
                    defaultValue: "感谢反馈，我们会尽快处理。",
                    comment: "Report success message"
                )
            )
        }
        .alert(
            String(
                localized: "community.report.failure.title",
                defaultValue: "举报失败",
                comment: "Report failure title"
            ),
            isPresented: reportFailureBinding
        ) {
            Button(String(localized: "action.ok", defaultValue: "好", comment: "OK")) {
                viewModel.dismissReportFeedback()
            }
        } message: {
            if case let .failure(message) = viewModel.reportState {
                Text(message)
            }
        }
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
            #if DEBUG
            postingComingSoonBar
            #endif
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
            .background(.bar)
        }
        .buttonStyle(.sparkPressable)
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
                CommentRow(reply: reply, relationship: .none)
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

    private var reportSuccessBinding: Binding<Bool> {
        Binding(
            get: { viewModel.reportState == .submitted },
            set: { if !$0 { viewModel.dismissReportFeedback() } }
        )
    }

    private var reportFailureBinding: Binding<Bool> {
        Binding(
            get: {
                if case .failure = viewModel.reportState { return true }
                return false
            },
            set: { if !$0 { viewModel.dismissReportFeedback() } }
        )
    }
}

#Preview {
    NavigationStack {
        CommunityPostDetailView(
            postID: "cp_1",
            coordinator: CommunityCoordinator(repository: MockCommunityPostsRepository())
        )
    }
}
