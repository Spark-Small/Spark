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
    @State private var commentComposer = CommunityPostCommentComposerState()

    private var post: CommunityPost? {
        model.post(id: postID)
    }

    var body: some View {
        Group {
            if let post {
                detailScroll(post)
            } else {
                ContentUnavailableView {
                    Label(CommunityBrowseCopy.postMissingTitle, systemImage: "photo.on.rectangle")
                } description: {
                    Text(CommunityBrowseCopy.postMissingDescription)
                }
            }
        }
        .alert(
            CommunityBrowseCopy.reportSheetTitle,
            isPresented: $showReportSheet
        ) {
            ForEach(CommunityBrowseCopy.reportReasons, id: \.self) { reason in
                Button(reason, role: .destructive) {
                    submitReport(reason: reason)
                }
            }
            Button(CommunityBrowseCopy.cancel, role: .cancel) {}
        } message: {
            Text(CommunityBrowseCopy.reportSheetMessage)
        }
        .communityAuthorSheet($authorDestination)
        .confirmationDialog(
            CommunityBrowseCopy.deleteConfirmTitle,
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button(CommunityBrowseCopy.deletePost, role: .destructive) {
                _ = model.deletePost(postID)
                dismiss()
            }
            Button(CommunityBrowseCopy.cancel, role: .cancel) {}
        } message: {
            Text(CommunityBrowseCopy.deleteConfirmMessage)
        }
        .platformFeedbackAlert(
            Binding(
                get: { model.presentation.toastMessage },
                set: { model.presentation.toastMessage = $0 }
            )
        )
    }

    private func submitReport(reason: String) {
        let title = model.post(id: postID)?.messageText ?? CommunityBrowseCopy.shareFallbackTitle
        guard model.reportPost(postID, reason: reason) else { return }
        app.addModerationTicket(
            postID: postID,
            title: title,
            reason: reason,
            targetKind: .communityPost
        )
        dismiss()
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

                CommunityPostActionBar(post: post, showsCommentEntry: false)
                    .communityRowToContentSpacing()

                if let activity = activities.activity(relatedTo: post) {
                    CommunityRelatedActivityLink(activity: activity)
                        .communityRowToContentSpacing()
                }

                if activities.activity(relatedTo: post) == nil {
                    Divider()
                        .communityRowToContentSpacing()
                } else {
                    Divider()
                        .communityInlineSpacing()
                }

                Text("\(CommunityBrowseCopy.commentsHeader) \(post.commentCount)")
                    .font(PlatformListTypography.headline)
                    .communityRowToContentSpacing()

                PlatformReviewsCommentsHost(
                    target: .community(post.id),
                    currentUserName: model.currentUserName,
                    layout: .embedded,
                    composerPlacement: .external,
                    externalDraft: commentComposer.draftBinding,
                    externalReplyTarget: commentComposer.replyTargetBinding,
                    contentOwnerName: post.author,
                    emptyTitle: CommunityBrowseCopy.commentsEmpty,
                    emptyHint: CommunityBrowseCopy.commentsPlaceholder,
                    placeholder: CommunityBrowseCopy.commentsPlaceholder,
                    onChanged: { model.syncComments(for: postID) },
                    refreshToken: model.commentRevision,
                    expandedThreadIDs: commentComposer.expandedThreadIDsBinding
                )
                .communityInlineSpacing()
            }
        }
        .platformMessageComposerBottomBar {
            PlatformReviewsCommentComposer(
                target: .community(post.id),
                currentUserName: model.currentUserName,
                draft: commentComposer.draftBinding,
                replyTarget: commentComposer.replyTargetBinding,
                expandedThreadIDs: commentComposer.expandedThreadIDsBinding,
                placeholder: CommunityBrowseCopy.commentsPlaceholder,
                onChanged: { model.syncComments(for: postID) }
            )
        }
        .communityDetailScrollChrome()
        .navigationTitle(CommunityBrowseCopy.detailTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { detailToolbar(for: post) }
    }

    @ToolbarContentBuilder
    private func detailToolbar(for post: CommunityPost) -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Menu {
                if model.isOwnPost(post) {
                    Button(CommunityBrowseCopy.deletePost, systemImage: "trash", role: .destructive) {
                        confirmDelete = true
                    }
                } else {
                    Button(CommunityBrowseCopy.reportPost, systemImage: "flag") {
                        showReportSheet = true
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .platformNavigationBarItemChrome()
            .accessibilityLabel(CommunityBrowseCopy.moreActions)
        }
    }
}

/// 社区详情内嵌评论：集中管理底栏输入栏与线程区共用的 draft / reply / 展开态。
@Observable
@MainActor
private final class CommunityPostCommentComposerState {
    var draft = ""
    var replyTarget: PlatformReview?
    var expandedThreadIDs: Set<UUID> = []

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

    var expandedThreadIDsBinding: Binding<Set<UUID>> {
        Binding(
            get: { self.expandedThreadIDs },
            set: { self.expandedThreadIDs = $0 }
        )
    }
}

#Preview {
    let app = AppModel.preview
    let postID = app.community.items.first?.id ?? UUID()
    return NavigationStack {
        CommunityPostDetailView(postID: postID)
            .environment(app.community)
            .environment(app.messages)
            .environment(app.activities)
            .environment(app.buddies)
    }
}
