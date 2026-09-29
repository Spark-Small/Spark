//
//  CommunityPostDetailView.swift
//  坐标系
//

import SwiftUI
import CoordinateModels

struct CommunityPostDetailView: View {
    let postID: CommunityPost.ID

    @Environment(CommunityModel.self) private var model
    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var showReportSheet = false
    @State private var confirmDelete = false
    @State private var authorDestination: CommunityAuthorDestination?
    @State private var photoDestination: CommunityPhotoDestination?
    @State private var commentComposer = CommunityPostCommentComposerState()

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
        .communityPhotoCover($photoDestination)
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
                        Button {
                            photoDestination = CommunityPhotoDestination(
                                photos: post.displayPhotos,
                                startIndex: index
                            )
                        } label: {
                            CommunityRemotePhoto(ref: post.displayPhotos[index])
                        }
                        .buttonStyle(.plain)
                    }
                    .communityRowToContentSpacing()
                }

                CommunityPostActionBar(post: post, showsCommentEntry: false)
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

                Text("评论 \(post.commentCount)")
                    .font(.headline)
                    .communityRowToContentSpacing()

                PlatformReviewsCommentsHost(
                    target: .community(post.id),
                    currentUserName: model.currentUserName,
                    layout: .embedded,
                    composerPlacement: .external,
                    externalDraft: commentComposer.draftBinding,
                    externalReplyTarget: commentComposer.replyTargetBinding,
                    contentOwnerName: post.author,
                    emptyTitle: "还没有评论，来抢沙发吧",
                    emptyHint: "我来说两句…",
                    placeholder: "我来说两句...",
                    onChanged: { model.syncComments(for: postID) }
                )
                .communityInlineSpacing()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PlatformReviewsCommentComposer(
                target: .community(post.id),
                currentUserName: model.currentUserName,
                draft: commentComposer.draftBinding,
                replyTarget: commentComposer.replyTargetBinding,
                placeholder: "我来说两句...",
                onChanged: { model.syncComments(for: postID) }
            )
        }
        .communityDetailScrollChrome()
        .id(model.commentRevision)
        .navigationTitle("分享详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailToolbar(for: post) }
    }

    @ToolbarContentBuilder
    private func detailToolbar(for post: CommunityPost) -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
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
            .accessibilityLabel("更多")
        }
    }
}

/// 社区详情内嵌评论：集中管理底栏输入栏与线程区共用的 draft / reply 状态。
@Observable
@MainActor
private final class CommunityPostCommentComposerState {
    var draft = ""
    var replyTarget: PlatformReview?

    var draftBinding: Binding<String> {
        Binding(
            get: { self.draft },
            set: { self.draft = $0 }
        )
    }

    var replyTargetBinding: Binding<PlatformReview?> {
        Binding(
            get: { self.replyTarget },
            set: { self.replyTarget = $0 }
        )
    }
}

#Preview {
  let app = AppModel.preview
  return NavigationStack {
        CommunityPostDetailView(postID: SampleData.posts[0].id)
            .environment(app.community)
            .environment(app.messages)
            .environment(app.activities)
            .environment(app.buddies)
    }
}
