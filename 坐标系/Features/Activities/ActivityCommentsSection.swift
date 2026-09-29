//
//  ActivityCommentsSection.swift
//  坐标系
//
//  活动详情评论 Sheet 与预览段。
//

import SwiftUI
import CoordinateModels

// MARK: - 评论

/// 活动评论 Sheet：与社区同款 List + 底栏输入。
struct ActivityCommentsSheet: View {
    let activityID: Activity.ID
    let hostName: String
    let currentUserName: String
    var onChanged: () -> Void = {}

    @State private var refreshID = 0

    private var rootCount: Int {
        PlatformReviewsStore.reviews(for: .activity(activityID)).filter(\.isRoot).count
    }

    var body: some View {
        NavigationStack {
            PlatformReviewsCommentsHost(
                target: .activity(activityID),
                currentUserName: currentUserName,
                layout: .sheetList,
                contentOwnerName: hostName,
                ownerBadgeTitle: "发起人",
                emptyTitle: ActivityDetailCopy.commentsEmpty,
                emptyHint: ActivityDetailCopy.commentsEmptyHint,
                placeholder: ActivityDetailCopy.commentsPlaceholder,
                onChanged: {
                    refreshID += 1
                    onChanged()
                }
            )
            .id(refreshID)
            .navigationTitle(rootCount == 0 ? "评论" : "评论 \(rootCount)")
            .navigationBarTitleDisplayMode(.inline)
            .platformSheetCancellationToolbar(MessagesCopy.close)
        }
        .platformSheet(.form)
    }
}

/// 详情页评论摘要：最多 2 条预览 + 进入完整评论区。
struct ActivityDetailCommentsPreviewSection: View {
    let activityID: Activity.ID
    let hostName: String
    var onOpenComments: () -> Void

    private var reviews: [PlatformReview] {
        PlatformReviewsStore.reviews(for: .activity(activityID))
    }

    private var rootCount: Int {
        reviews.filter(\.isRoot).count
    }

    private var previewRoots: [PlatformReview] {
        Array(PlatformReviewCatalog.sortedRoots(reviews).prefix(2))
    }

    var body: some View {
        Section {
            VStack(alignment: .leading) {
                if previewRoots.isEmpty {
                    Text(ActivityDetailCopy.commentsEmptyHint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Button(action: onOpenComments) {
                        VStack(alignment: .leading) {
                            ForEach(previewRoots) { review in
                                CommunityCommentRow(
                                    comment: review.asCommunityComment,
                                    style: .thread,
                                    showsLike: false,
                                    showsTranslate: false,
                                    contentOwnerName: hostName,
                                    ownerBadgeTitle: "发起人"
                                )
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onOpenComments) {
                    Label(
                        rootCount == 0
                            ? ActivityDetailCopy.commentsWriteFirst
                            : ActivityDetailCopy.commentsViewAll,
                        systemImage: "bubble.right"
                    )
                }
            }
        } header: {
            Text(ActivityDetailCopy.commentsCountTitle(rootCount))
        }
    }
}
