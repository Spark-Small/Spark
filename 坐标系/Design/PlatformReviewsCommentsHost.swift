//
//  PlatformReviewsCommentsHost.swift
//  坐标系
//
//  统一评价 / 评论线程宿主。
//

import SwiftUI

// MARK: - Unified host

/// 统一评论宿主：系统 List / Form 样式，楼中楼与回复。
struct PlatformReviewsCommentsHost: View {
    enum Layout {
        case formRows
        case sheetList
        case embedded
    }

    enum ComposerPlacement {
        case inline
        case external
    }

    let target: PlatformReviewTarget
    let currentUserName: String
    var layout: Layout
    var composerPlacement: ComposerPlacement = .inline
    var externalDraft: Binding<String>? = nil
    var externalReplyTarget: Binding<PlatformReview?>? = nil
    var contentOwnerName: String? = nil
    var ownerBadgeTitle = PlatformReviewsCopy.ownerBadgeDefault
    var emptyTitle: String = ActivityDetailCopy.commentsEmpty
    var emptyHint: String = ActivityDetailCopy.commentsEmptyHint
    var placeholder: String = ActivityDetailCopy.commentsPlaceholder
    var companionFilter: Binding<PlatformReviewFilter>? = nil
    var companionStats: PlatformReviewStats? = nil
    /// 陪玩口碑区只读展示时为 false（写评价走订单凭证）。
    var allowsReply: Bool = true
    var onChanged: () -> Void = {}
    /// 外部驱动刷新（社区详情 commentRevision），避免整页 `.id` 重置展开态。
    var refreshToken: Int = 0
    /// 与外部 Composer 共享展开态；nil 时用内部 State。
    var expandedThreadIDs: Binding<Set<UUID>>? = nil

    // 跨文件 +Composer 需 internal。
    @State var internalDraft = ""
    @State var internalReplyTarget: PlatformReview?
    @State var reviews: [PlatformReview] = []
    @State var internalExpandedThreadIDs: Set<UUID> = []
    @State var didApplyDefaultExpansion = false
    @State var blockedWord: String?
    @State var showWriteSheet = false
    @FocusState var focused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var draftBinding: Binding<String> {
        externalDraft ?? $internalDraft
    }

    var replyTargetBinding: Binding<PlatformReview?> {
        externalReplyTarget ?? $internalReplyTarget
    }

    var expandedIDsBinding: Binding<Set<UUID>> {
        expandedThreadIDs ?? $internalExpandedThreadIDs
    }

    var draft: String {
        get { draftBinding.wrappedValue }
        nonmutating set { draftBinding.wrappedValue = newValue }
    }

    var replyTarget: PlatformReview? {
        get { replyTargetBinding.wrappedValue }
        nonmutating set { replyTargetBinding.wrappedValue = newValue }
    }

    var expandedIDs: Set<UUID> {
        get { expandedIDsBinding.wrappedValue }
        nonmutating set { expandedIDsBinding.wrappedValue = newValue }
    }

    var displayedRoots: [PlatformReview] {
        if let companionFilter {
            return PlatformReviewCatalog.filtered(
                reviews,
                filter: companionFilter.wrappedValue
            )
        }
        return PlatformReviewCatalog.sortedRoots(reviews)
    }

    var showsInlineComposer: Bool {
        composerPlacement == .inline && layout == .formRows
    }

    var usesListStyling: Bool {
        switch layout {
        case .formRows, .sheetList: return true
        case .embedded: return false
        }
    }

    var commentRowStyle: CommunityCommentRowStyle {
        switch layout {
        case .formRows:
            return .form
        case .sheetList, .embedded:
            return .thread
        }
    }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            switch layout {
            case .formRows:
                formAccessoryRows
                commentListContent
                if showsInlineComposer {
                    inlineComposerRow
                }
            case .sheetList:
                List {
                    formAccessoryRows
                    commentListContent
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.visible)
                .contentMargins(.top, 0, for: .scrollContent)
                .platformMessageComposerBottomBar {
                    bottomComposer
                }
            case .embedded:
                commentListContent
                if showsInlineComposer {
                    inlineComposerRow
                }
            }
        }
        .onAppear(perform: reload)
        .onChange(of: refreshToken) { _, _ in
            reload()
        }
        .alert(PlatformReviewsCopy.needsEditTitle, isPresented: Binding(
            get: { blockedWord != nil },
            set: { if !$0 { blockedWord = nil } }
        )) {
            Button(PlatformReviewsCopy.needsEditDismiss, role: .cancel) {}
        } message: {
            Text(blockedWord ?? "")
        }
    }

    @ViewBuilder
    private var formAccessoryRows: some View {
        if let companionFilter, let companionStats {
            PlatformReviewFilterBar(filter: companionFilter, stats: companionStats)
                .modifier(FormAccessoryRowModifier())
        }
    }

    @ViewBuilder
    private var commentListContent: some View {
        if displayedRoots.isEmpty {
            ContentUnavailableView(
                emptyTitle,
                systemImage: "bubble.right",
                description: Text(emptyHint)
            )
            .modifier(OptionalListRowBackgroundModifier(enabled: usesListStyling))
        } else {
            ForEach(displayedRoots) { root in
                threadBlock(root)
            }
        }
    }

    @ViewBuilder
    private func threadBlock(_ root: PlatformReview) -> some View {
        let replies = reviews
            .filter { $0.parentID == root.id }
            .sorted { $0.postedAt < $1.postedAt }
        let isExpanded = expandedIDs.contains(root.id)

        VStack(alignment: .leading) {
            reviewContent(root, isReply: false)

            if !replies.isEmpty {
                if isExpanded {
                    ForEach(replies) { reply in
                        reviewContent(reply, isReply: true)
                    }
                    threadToggleButton(title: PlatformReviewsCopy.collapseReplies) {
                        expandedIDs.remove(root.id)
                    }
                } else {
                    threadToggleButton(
                        title: PlatformReviewsCopy.expandReplies(count: replies.count)
                    ) {
                        expandedIDs.insert(root.id)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ReviewRowInteractionModifier(
            review: root,
            currentUserName: currentUserName,
            onDelete: { delete(root) }
        ))
        .modifier(PlatformReviewsListRowModifier(enabled: usesListStyling))
        .padding(.horizontal, usesListStyling || layout == .embedded ? 0 : PlatformMetrics.contentInset)
        .padding(.vertical, usesListStyling ? 0 : PlatformConversationListRow.verticalInset)
    }

    @ViewBuilder
    private func threadToggleButton(title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(PlatformListTypography.footnote)
            .foregroundStyle(.secondary)
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, threadToggleLeadingInset)
            .accessibilityHint(PlatformReviewsCopy.expandCollapseHint)
    }

    private var threadToggleLeadingInset: CGFloat {
        switch layout {
        case .sheetList, .embedded:
            dynamicTypeSize.commentThreadReplyLeadingInset
        case .formRows:
            0
        }
    }

    @ViewBuilder
    private func reviewContent(_ review: PlatformReview, isReply: Bool) -> some View {
        if review.hasRating, !isReply {
            PlatformReviewRatedCard(
                review: review,
                usesFormRowStyle: usesListStyling,
                isLiked: review.isLiked,
                onLike: { toggleLike(review) },
                onDislike: { toggleDislike(review) },
                onReply: allowsReply ? { beginReply(to: review) } : nil
            )
            .contextMenu {
                if allowsReply {
                    Button(PlatformReviewsCopy.reply, systemImage: "arrowshape.turn.up.left") {
                        beginReply(to: review)
                    }
                }
                if review.isOwned(by: currentUserName) {
                    Button(PlatformReviewsCopy.delete, systemImage: "trash", role: .destructive) {
                        delete(review)
                    }
                }
            }
        } else {
            CommunityCommentRow(
                comment: review.asCommunityComment,
                style: commentRowStyle,
                isReply: isReply,
                showsLike: true,
                isLiked: review.isLiked,
                isDisliked: review.isDisliked,
                contentOwnerName: contentOwnerName,
                ownerBadgeTitle: ownerBadgeTitle,
                onLike: { toggleLike(review) },
                onDislike: { toggleDislike(review) },
                onReply: allowsReply ? { beginReply(to: review) } : nil
            )
            .contextMenu {
                if allowsReply {
                    Button(PlatformReviewsCopy.reply, systemImage: "arrowshape.turn.up.left") {
                        beginReply(to: review)
                    }
                }
                if review.isOwned(by: currentUserName) {
                    Button(PlatformReviewsCopy.delete, systemImage: "trash", role: .destructive) {
                        delete(review)
                    }
                }
            }
        }
    }

}

