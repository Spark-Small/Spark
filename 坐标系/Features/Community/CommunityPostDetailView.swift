//
//  CommunityPostDetailView.swift
//  坐标系
//

import SwiftUI

struct CommunityPostDetailView: View {
    let postID: CommunityPost.ID

    @Environment(CommunityModel.self) private var model
    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var draft = ""
    @State private var showBookmarkSheet = false
    @State private var showReportSheet = false
    @State private var confirmDelete = false
    @State private var authorDestination: CommunityAuthorDestination?
    @State private var blockedCommentWord: String?
    @FocusState private var isCommentFocused: Bool

    private var post: CommunityPost? {
        model.post(id: postID)
    }

    var body: some View {
        Group {
            if let post {
                detailScroll(post)
            } else {
                ContentUnavailableView("动态不存在", systemImage: "photo.on.rectangle")
            }
        }
        .platformSecondaryPage()
        .sheet(isPresented: $showBookmarkSheet) {
            CommunityBookmarkSheet(postID: postID)
        }
        .alert(
            "举报这条分享",
            isPresented: $showReportSheet
        ) {
            ForEach(["垃圾广告", "不实信息", "色情低俗", "人身攻击", "其他"], id: \.self) { reason in
                Button(reason, role: .destructive) {
                    submitReport(reason: reason)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("选择举报原因。举报后内容会从你的信息流中隐藏。")
        }
        .communityAuthorSheet($authorDestination)
        .confirmationDialog(
            "删除这条分享？",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                _ = model.deletePost(postID)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复")
        }
        .alert("评论需要修改", isPresented: Binding(
            get: { blockedCommentWord != nil },
            set: { if !$0 { blockedCommentWord = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("检测到敏感词「\(blockedCommentWord ?? "")」，请修改后再发送。")
        }
    }

    private func submitReport(reason: String) {
        let title = model.post(id: postID)?.messageText ?? "分享"
        _ = model.reportPost(postID, reason: reason)
        app.addModerationTicket(
            postID: postID,
            title: title,
            reason: reason,
            targetKind: .communityPost
        )
    }

    private func detailScroll(_ post: CommunityPost) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                CommunityPostAuthorHeader(post: post) {
                    authorDestination = buddies.authorDestination(for: post.author)
                }

                CommunityPostBodySection(post: post)
                    .communityInlineSpacing()

                if !post.displayPhotos.isEmpty {
                    CommunityMediaPager(pageCount: post.displayPhotos.count) { index in
                        CommunityRemotePhoto(ref: post.displayPhotos[index])
                    }
                    .communityRowToContentSpacing()
                }

                CommunityPostActionBar(post: post)
                    .communityRowToContentSpacing()

                if let activity = activities.activity(relatedTo: post) {
                    CommunityRelatedActivityLink(activity: activity, showsEventTime: true)
                        .communityRowToContentSpacing()
                }

                Divider()
                    .padding(
                        .top,
                        activities.activity(relatedTo: post) == nil
                            ? PlatformConversationListRow.rowToContentSpacing
                            : PlatformConversationListRow.textToSecondarySpacing
                    )

                Text("评论 \(post.comments.count)")
                    .font(.headline)
                    .communityRowToContentSpacing()

                if post.comments.isEmpty {
                    Text("还没有评论，来抢沙发吧")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .communityInlineSpacing()
                } else {
                    ForEach(post.comments.filter { $0.parentID == nil }) { comment in
                        CommunityCommentRow(
                            comment: comment,
                            allowsTextSelection: true,
                            showsLike: true,
                            isLiked: model.isCommentLiked(comment.id),
                            onLike: {
                                model.toggleCommentLike(postID: post.id, commentID: comment.id)
                            }
                        )
                        .communityInlineSpacing()
                        .contextMenu {
                            if model.isOwnComment(comment) {
                                Button("删除评论", role: .destructive) {
                                    model.deleteComment(postID: post.id, commentID: comment.id)
                                }
                            }
                        }
                    }
                }
            }
        }
        .communityDetailScrollChrome()
        .navigationTitle("分享详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailToolbar(for: post) }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CommunityCommentComposer(
                draft: $draft,
                placeholder: "我来说两句...",
                authorName: model.currentUserName,
                isFocused: $isCommentFocused,
                onSend: sendComment
            )
        }
    }

    @ToolbarContentBuilder
    private func detailToolbar(for post: CommunityPost) -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("收藏", systemImage: "bookmark") {
                    showBookmarkSheet = true
                }
                if model.isOwnPost(post) {
                    Button("删除", systemImage: "trash", role: .destructive) {
                        confirmDelete = true
                    }
                } else {
                    Button("举报", systemImage: "flag") {
                        showReportSheet = true
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    private func sendComment() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        switch model.addComment(to: postID, text: draft) {
        case .posted:
            draft = ""
            isCommentFocused = false
        case .blocked(let word):
            blockedCommentWord = word
        case .invalid:
            break
        }
    }
}

#Preview {
    NavigationStack {
        CommunityPostDetailView(postID: SampleData.posts[0].id)
            .environment(CommunityModel())
            .environment(MessagesModel())
            .environment(ActivitiesModel())
            .environment(BuddiesModel())
    }
}
