// Module: SparkCommunity — Community post detail presentation.

import SparkDesignSystem
import SwiftUI

// REASONING: Detail pager is read-only for images; videos keep inline playback controls.

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
        ScrollView {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.sectionVerticalPadding) {
                    postHeader(post: post)
                    repliesSection(post: post)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.sectionVerticalPadding)
        }
        .safeAreaInset(edge: .bottom) {
            CommunityReplyComposer(
                draft: $viewModel.replyDraft,
                isSending: viewModel.replyState == .sending,
                errorMessage: replyErrorMessage,
                onSend: {
                    Task { await viewModel.sendReply() }
                }
            )
        }
        .accessibilityElement(children: .contain)
    }

    private var replyErrorMessage: String? {
        if case .failure(let message) = viewModel.replyState {
            return message
        }
        return nil
    }

    private func postHeader(post: CommunityPostDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                Text(post.authorDisplayName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                if let linkedActivity = post.linkedActivity {
                    CommunityPostLinkedActivitySummaryCard(activity: linkedActivity) {
                        onOpenLinkedActivity?(linkedActivity.id)
                    }
                    .disabled(onOpenLinkedActivity == nil)
                }

                if !post.galleryMedia.isEmpty {
                    CommunityPostMediaPager(
                        mediaItems: post.galleryMedia,
                        usesInsetMedia: false,
                        horizontalPadding: SparkLayoutMetrics.standardHorizontalPadding,
                        onOpen: {}
                    )
                    .allowsHitTesting(post.galleryMedia.contains { $0.kind == .video })
                }

                Text(post.body)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(SparkLayoutMetrics.communityFeedBodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)

                CommunityPostTagsRow(tags: post.tags)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(post.title), \(post.authorDisplayName)")

            CommunityPostLikeControl(
                isLiked: post.viewerHasLiked,
                likeCount: post.likeCount,
                isPending: viewModel.isLikePending,
                onToggle: { Task { await viewModel.toggleLike() } }
            )
            .font(.subheadline)
        }
    }

    private func repliesSection(post: CommunityPostDetail) -> some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.communityFeedBlockSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text(repliesSectionTitle(count: post.replyCount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                if viewModel.showsReplySortControl {
                    Picker(
                        String(
                            localized: "community.replies.sort.a11y",
                            defaultValue: "评论排序",
                            comment: "Reply sort picker accessibility label"
                        ),
                        selection: $viewModel.replySortMode
                    ) {
                        ForEach(CommunityPostReplySortMode.allCases) { mode in
                            Text(mode.localizedTitle).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .font(.footnote)
                    .accessibilityLabel(
                        String(
                            localized: "community.replies.sort.a11y",
                            defaultValue: "评论排序",
                            comment: "Reply sort picker accessibility label"
                        )
                    )
                }
            }

            if post.replies.isEmpty {
                Text(
                    String(
                        localized: "community.replies.empty",
                        defaultValue: "还没有评论，来抢沙发吧",
                        comment: "No comments yet"
                    )
                )
                .font(.footnote)
                .foregroundStyle(.tertiary)
            } else {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.displayedReplies) { reply in
                        CommentRow(reply: reply, relationship: reply.relationshipToViewer)
                            .padding(.vertical, SparkLayoutMetrics.communityRowVerticalPadding)
                        if reply.id != viewModel.displayedReplies.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func repliesSectionTitle(count: Int) -> String {
        let format = String(
            localized: "community.replies.section.title.format",
            defaultValue: "评论 · %lld",
            comment: "Comments section with count; %lld is count"
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
    CommunityPreviewTraits.matrix("Post detail") {
        NavigationStack {
            CommunityPostDetailView(
                postID: "cp_recap_mock",
                coordinator: CommunityCoordinator(repository: MockCommunityPostsRepository())
            )
        }
    }
}
