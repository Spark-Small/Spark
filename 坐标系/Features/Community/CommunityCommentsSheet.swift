//
//  CommunityCommentsSheet.swift
//  坐标系
//

import SwiftUI
import CoordinateModels

struct CommunityCommentsSheet: View {
    let postID: CommunityPost.ID

    @Environment(CommunityModel.self) private var model

    private var post: CommunityPost? { model.post(id: postID) }

    var body: some View {
        NavigationStack {
            Group {
                if post != nil {
                    PlatformReviewsCommentsHost(
                        target: .community(postID),
                        currentUserName: model.currentUserName,
                        layout: .sheetList,
                        contentOwnerName: post?.author,
                        emptyTitle: CommunityBrowseCopy.commentsEmpty,
                        emptyHint: CommunityBrowseCopy.commentsPlaceholder,
                        placeholder: CommunityBrowseCopy.commentsPlaceholder,
                        onChanged: { model.syncComments(for: postID) },
                        refreshToken: model.commentRevision
                    )
                } else {
                    ContentUnavailableView(
                        CommunityBrowseCopy.postMissingTitle,
                        systemImage: "bubble.right"
                    )
                }
            }
            .navigationTitle(
                post.map { CommunityBrowseCopy.commentsSheetTitle(count: $0.commentCount) }
                    ?? CommunityBrowseCopy.commentsSheetTitle
            )
            .navigationBarTitleDisplayMode(.inline)
            .platformSheetCancellationToolbar(MessagesCopy.close)
        }
        .platformSheet(.form)
    }
}
