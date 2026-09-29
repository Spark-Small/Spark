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
    var ownerBadgeTitle = "作者"
    var emptyTitle: String = ActivityDetailCopy.commentsEmpty
    var emptyHint: String = ActivityDetailCopy.commentsEmptyHint
    var placeholder: String = ActivityDetailCopy.commentsPlaceholder
    var showsTranslate = false
    var companionFilter: Binding<PlatformReviewFilter>? = nil
    var companionStats: PlatformReviewStats? = nil
    var onTranslate: ((PlatformReview) -> Void)? = nil
    var onChanged: () -> Void = {}

    @State private var internalDraft = ""
    @State private var internalReplyTarget: PlatformReview?
    @State private var reviews: [PlatformReview] = []
    @State private var expandedThreadIDs: Set<UUID> = []
    @State private var blockedWord: String?
    @FocusState private var focused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var draftBinding: Binding<String> {
        externalDraft ?? $internalDraft
    }

    private var replyTargetBinding: Binding<PlatformReview?> {
        externalReplyTarget ?? $internalReplyTarget
    }

    private var draft: String {
        get { draftBinding.wrappedValue }
        nonmutating set { draftBinding.wrappedValue = newValue }
    }

    private var replyTarget: PlatformReview? {
        get { replyTargetBinding.wrappedValue }
        nonmutating set { replyTargetBinding.wrappedValue = newValue }
    }

    private var displayedRoots: [PlatformReview] {
        if let companionFilter {
            return PlatformReviewCatalog.filtered(
                reviews,
                filter: companionFilter.wrappedValue
            )
        }
        return PlatformReviewCatalog.sortedRoots(reviews)
    }

    private var showsInlineComposer: Bool {
        composerPlacement == .inline && layout == .formRows
    }

    private var usesListStyling: Bool {
        switch layout {
        case .formRows, .sheetList: return true
        case .embedded: return false
        }
    }

    private var commentRowStyle: CommunityCommentRowStyle {
        switch layout {
        case .formRows:
            return .form
        case .sheetList, .embedded:
            return .thread
        }
    }

    private var canSend: Bool {
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
                .safeAreaInset(edge: .bottom, spacing: 0) {
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
        .alert("评论需要修改", isPresented: Binding(
            get: { blockedWord != nil },
            set: { if !$0 { blockedWord = nil } }
        )) {
            Button("知道了", role: .cancel) {}
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
        let replies = reviews.filter { $0.parentID == root.id }
        let isExpanded = expandedThreadIDs.contains(root.id)

        VStack(alignment: .leading) {
            reviewContent(root, isReply: false)

            if !replies.isEmpty {
                if isExpanded {
                    ForEach(replies) { reply in
                        reviewContent(reply, isReply: true)
                    }
                    threadToggleButton(title: "收起回复") {
                        expandedThreadIDs.remove(root.id)
                    }
                } else {
                    threadToggleButton(
                        title: replies.count == 1 ? "展开 1 条回复" : "展开 \(replies.count) 条回复"
                    ) {
                        expandedThreadIDs.insert(root.id)
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
        .padding(.horizontal, usesListStyling ? 0 : PlatformMetrics.contentInset)
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
                onReply: { beginReply(to: review) }
            )
            .contextMenu {
                Button("回复", systemImage: "arrowshape.turn.up.left") {
                    beginReply(to: review)
                }
                if review.isOwned(by: currentUserName) {
                    Button("删除", systemImage: "trash", role: .destructive) {
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
                showsTranslate: showsTranslate,
                contentOwnerName: contentOwnerName,
                ownerBadgeTitle: ownerBadgeTitle,
                onLike: { toggleLike(review) },
                onDislike: { toggleDislike(review) },
                onReply: { beginReply(to: review) },
                onTranslate: { onTranslate?(review) }
            )
            .contextMenu {
                Button("回复", systemImage: "arrowshape.turn.up.left") {
                    beginReply(to: review)
                }
                if review.isOwned(by: currentUserName) {
                    Button("删除", systemImage: "trash", role: .destructive) {
                        delete(review)
                    }
                }
            }
        }
    }

    private var bottomComposer: some View {
        PlatformMessageComposerBar(
            draft: draftBinding,
            placeholder: replyTarget == nil
                ? placeholder
                : "回复 \(replyTarget?.author ?? "")…",
            isEnabled: true,
            canSend: canSend,
            isFocused: $focused,
            replyPreview: replyTarget.map { ($0.author, $0.text) },
            onCancelReply: { replyTarget = nil },
            onSend: send
        )
    }

    @ViewBuilder
    private var inlineComposerRow: some View {
        if showsInlineComposer {
            TextField(placeholder, text: draftBinding, axis: .vertical)
                .lineLimit(1...4)
                .focused($focused)
                .submitLabel(.send)
                .onSubmit(send)
                .platformMessagesSeparatorsHidden()
        }
    }

    private func reload() {
        reviews = PlatformReviewsStore.reviews(for: target)
    }

    private func beginReply(to review: PlatformReview) {
        replyTarget = review
        focused = true
    }

    private func toggleLike(_ review: PlatformReview) {
        PlatformReviewsStore.toggleLike(reviewID: review.id, target: target)
        reload()
        onChanged()
    }

    private func toggleDislike(_ review: PlatformReview) {
        PlatformReviewsStore.toggleDislike(reviewID: review.id, target: target)
        reload()
        onChanged()
    }

    private func send() {
        let outcome = PlatformReviewSubmission.submit(
            draft,
            target: target,
            author: currentUserName,
            parent: replyTarget
        )
        if let blockedWord = outcome.blockedWord {
            self.blockedWord = blockedWord
            return
        }
        if let parentID = outcome.expandedParentID {
            expandedThreadIDs.insert(parentID)
        }
        draft = ""
        replyTarget = nil
        focused = false
        reload()
        onChanged()
    }

    private func delete(_ review: PlatformReview) {
        if replyTarget?.id == review.id { replyTarget = nil }
        PlatformReviewsStore.delete(reviewID: review.id, target: target, author: currentUserName)
        reload()
        onChanged()
    }
}

